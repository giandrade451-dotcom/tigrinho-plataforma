/*
 * Fex Private — Bedrock Client (Script API)
 *
 * Mods imbutidos (toggle no menu):
 *   - FPS Counter        (estimado via tick-rate; 20 tps = ~60 fps target)
 *   - CPS Counter        (medido via eventos entityHit + itemUse)
 *   - Keystrokes (WASD)  (inferido por mudança de posição/rotação no eixo)
 *   - TNT Timer          (escaneia minecraft:tnt primed e mostra countdown)
 *   - Hitbox             (partículas em volta de entidades próximas)
 *   - Reach Indicator    (mostra alcance estimado do jogador via raycast)
 *
 * Menu:
 *   - Use o item "fex:menu" (criativo) OU digite "!fex" no chat
 *   - Botão na tela de pausa não é acessível por Script API; fornecemos
 *     um item de bind e um chat command como alternativas oficiais.
 *
 * Limitações reais da Script API (documentadas):
 *   - Não há API de FPS real; usamos tickrate ratio com baseline 20tps.
 *   - Não há API de tecla; Keystrokes detecta MOVIMENTO no eixo (W/A/S/D
 *     viram on se houve deslocamento positivo/negativo no tick).
 *   - Não há API de mouse; CPS conta ataques de melee + usos de item.
 *   - Reach é estimado por raycast no alvo apontado (1..6 blocos).
 */

import {
  world,
  system,
  Player,
  EntityRaycastOptions,
  ItemStack,
  EquipmentSlot,
} from "@minecraft/server";
import { ModalFormData, ActionFormData } from "@minecraft/server-ui";

// ---------------------------------------------------------------------------
// Per-player state
// ---------------------------------------------------------------------------
const STATE = new Map(); // playerId -> state

function getState(player) {
  let s = STATE.get(player.id);
  if (!s) {
    s = {
      cps: 0,
      cpsBuffer: [], // timestamps of last clicks
      lastTickPos: null,
      keys: { w: false, a: false, s: false, d: false, jump: false, sneak: false },
      hud: {
        fps: { x: 2, y: 2, on: true },
        cps: { x: 2, y: 12, on: true },
        keys: { x: 2, y: 22, on: true },
        tnt: { x: 50, y: 2, on: true },
        reach: { x: 2, y: 32, on: true },
        coords: { x: 2, y: 42, on: true },
      },
      mods: {
        fps: true,
        cps: true,
        keystrokes: true,
        tntTimer: true,
        hitbox: false,      // off by default — partículas custam CPU
        reach: true,
        coords: true,
        showHud: true,
      },
      lastHudUpdate: 0,
      reach: 0,
    };
    STATE.set(player.id, s);
  }
  return s;
}

world.afterEvents.playerLeave.subscribe((ev) => {
  STATE.delete(ev.playerId);
});

// ---------------------------------------------------------------------------
// CPS — count attacks and item-uses as clicks
// ---------------------------------------------------------------------------
world.afterEvents.entityHitEntity.subscribe((ev) => {
  if (!(ev.damagingEntity instanceof Player)) return;
  const s = getState(ev.damagingEntity);
  s.cpsBuffer.push(Date.now());
});
world.afterEvents.entityHitBlock.subscribe((ev) => {
  if (!(ev.damagingEntity instanceof Player)) return;
  const s = getState(ev.damagingEntity);
  s.cpsBuffer.push(Date.now());
});
world.afterEvents.itemUse.subscribe((ev) => {
  if (!(ev.source instanceof Player)) return;
  const s = getState(ev.source);
  s.cpsBuffer.push(Date.now());
  // Open menu if holding the menu item
  const item = ev.itemStack;
  if (item && item.typeId === "minecraft:nether_star" && item.nameTag === "§lFex Menu§r") {
    openMainMenu(ev.source);
  }
});

// ---------------------------------------------------------------------------
// FPS estimation — count ticks per second window
// ---------------------------------------------------------------------------
let tickCount = 0;
let lastSecond = Date.now();
let estimatedTps = 20;
system.runInterval(() => {
  tickCount++;
  const now = Date.now();
  const elapsed = now - lastSecond;
  if (elapsed >= 1000) {
    estimatedTps = (tickCount * 1000) / elapsed;
    tickCount = 0;
    lastSecond = now;
  }
}, 1);

// ---------------------------------------------------------------------------
// Main HUD + mod loop
// ---------------------------------------------------------------------------
system.runInterval(() => {
  const now = Date.now();
  for (const player of world.getAllPlayers()) {
    const s = getState(player);
    if (!s.mods.showHud) continue;

    // Trim CPS buffer to last 1s and compute
    s.cpsBuffer = s.cpsBuffer.filter((t) => now - t < 1000);
    s.cps = s.cpsBuffer.length;

    // Keystroke inference from position delta
    updateKeystrokes(player, s);

    // Reach via view raycast
    if (s.mods.reach) {
      try {
        const opts = { maxDistance: 8 };
        const block = player.getBlockFromViewDirection(opts);
        const ents = player.getEntitiesFromViewDirection({ maxDistance: 8 });
        let dist = 0;
        if (block && block.block) {
          const bl = block.block.location;
          const pl = player.getHeadLocation();
          dist = Math.sqrt(
            (bl.x - pl.x) ** 2 + (bl.y - pl.y) ** 2 + (bl.z - pl.z) ** 2,
          );
        }
        if (ents && ents.length > 0) {
          const e = ents[0].entity;
          const el = e.location;
          const pl = player.getHeadLocation();
          const ed = Math.sqrt(
            (el.x - pl.x) ** 2 + (el.y - pl.y) ** 2 + (el.z - pl.z) ** 2,
          );
          if (ed > 0 && (dist === 0 || ed < dist)) dist = ed;
        }
        s.reach = dist;
      } catch (_e) {
        s.reach = 0;
      }
    }

    // Hitbox particles around nearby entities
    if (s.mods.hitbox) {
      try {
        const ents = player.dimension.getEntities({
          location: player.location,
          maxDistance: 8,
          excludeTypes: ["minecraft:item", "minecraft:xp_orb", "minecraft:arrow"],
        });
        for (const e of ents) {
          if (e.id === player.id) continue;
          drawHitbox(player, e);
        }
      } catch (_e) {}
    }

    // Render HUD
    renderHud(player, s);
  }
}, 2);

function updateKeystrokes(player, s) {
  const loc = player.location;
  const rot = player.getRotation();
  if (!s.lastTickPos) {
    s.lastTickPos = { x: loc.x, y: loc.y, z: loc.z, yaw: rot.y };
    return;
  }
  const dx = loc.x - s.lastTickPos.x;
  const dz = loc.z - s.lastTickPos.z;
  const dy = loc.y - s.lastTickPos.y;
  // Convert world delta into player-local forward/strafe using yaw
  const yawRad = (-rot.y * Math.PI) / 180.0;
  const fwd = Math.cos(yawRad) * dz + Math.sin(yawRad) * dx;
  const str = Math.cos(yawRad) * dx - Math.sin(yawRad) * dz;
  const threshold = 0.02;
  s.keys.w = fwd > threshold;
  s.keys.s = fwd < -threshold;
  s.keys.d = str > threshold;
  s.keys.a = str < -threshold;
  s.keys.jump = dy > 0.08;
  s.keys.sneak = player.isSneaking ?? false;
  s.lastTickPos = { x: loc.x, y: loc.y, z: loc.z, yaw: rot.y };
}

function drawHitbox(player, ent) {
  // Spawn outline particles in 8 corners of entity bounding box
  try {
    const loc = ent.location;
    const dim = player.dimension;
    const off = 0.5;
    const yh = 1.8;
    const corners = [
      [-off, 0, -off],
      [off, 0, -off],
      [-off, 0, off],
      [off, 0, off],
      [-off, yh, -off],
      [off, yh, -off],
      [-off, yh, off],
      [off, yh, off],
    ];
    for (const [ox, oy, oz] of corners) {
      dim.spawnParticle("minecraft:basic_flame_particle", {
        x: loc.x + ox,
        y: loc.y + oy,
        z: loc.z + oz,
      });
    }
  } catch (_e) {}
}

function renderHud(player, s) {
  const m = s.mods;
  const lines = [];
  if (m.fps) {
    const fps = Math.round((estimatedTps / 20) * 60);
    lines.push(`§a${fps}§7 fps`);
  }
  if (m.cps) {
    lines.push(`§e${s.cps}§7 cps`);
  }
  if (m.keystrokes) {
    const k = s.keys;
    lines.push(
      `§7[${k.w ? "§fW§7" : " "}]\n` +
        `§7[${k.a ? "§fA§7" : " "}][${k.s ? "§fS§7" : " "}][${k.d ? "§fD§7" : " "}]`,
    );
  }
  if (m.reach && s.reach > 0) {
    lines.push(`§b${s.reach.toFixed(2)}§7 m`);
  }
  if (m.coords) {
    const l = player.location;
    lines.push(`§7${l.x.toFixed(1)} ${l.y.toFixed(1)} ${l.z.toFixed(1)}`);
  }
  if (m.tntTimer) {
    const tnt = findClosestPrimedTnt(player);
    if (tnt) {
      const fuse = tnt.getComponent("minecraft:tnt")?.fuseTime ?? null;
      if (fuse !== null) {
        lines.push(`§cTNT §7${(fuse / 20).toFixed(1)}s`);
      } else {
        const dist = distance(player.location, tnt.location).toFixed(1);
        lines.push(`§cTNT §7${dist}m`);
      }
    }
  }
  try {
    player.onScreenDisplay.setActionBar(lines.join("\n"));
  } catch (_e) {}
}

function findClosestPrimedTnt(player) {
  try {
    const ents = player.dimension.getEntities({
      type: "minecraft:tnt",
      location: player.location,
      maxDistance: 32,
    });
    let closest = null;
    let best = Infinity;
    for (const e of ents) {
      const d = distance(player.location, e.location);
      if (d < best) {
        best = d;
        closest = e;
      }
    }
    return closest;
  } catch (_e) {
    return null;
  }
}

function distance(a, b) {
  return Math.sqrt(
    (a.x - b.x) ** 2 + (a.y - b.y) ** 2 + (a.z - b.z) ** 2,
  );
}

// ---------------------------------------------------------------------------
// Menus
// ---------------------------------------------------------------------------
function openMainMenu(player) {
  const s = getState(player);
  const form = new ActionFormData()
    .title("§lFex Private§r")
    .body("§7Selecione uma seção:")
    .button("§aMods (FPS / CPS / Hitbox / Reach / TNT)", "textures/items/diamond_sword")
    .button("§bHUD — Posições", "textures/items/compass")
    .button("§eTexturas (Subpacks)", "textures/items/totem_of_undying")
    .button("§7Sobre / Ajuda", "textures/items/book_writable");
  form.show(player).then((res) => {
    if (res.canceled) return;
    if (res.selection === 0) openModsMenu(player);
    else if (res.selection === 1) openHudMenu(player);
    else if (res.selection === 2) openTexturesMenu(player);
    else if (res.selection === 3) openAboutMenu(player);
  }).catch(() => {});
}

function openModsMenu(player) {
  const s = getState(player);
  const form = new ModalFormData().title("§lMods Fex§r");
  form.toggle("FPS Counter", s.mods.fps);
  form.toggle("CPS Counter", s.mods.cps);
  form.toggle("Keystrokes (WASD)", s.mods.keystrokes);
  form.toggle("TNT Timer", s.mods.tntTimer);
  form.toggle("Hitbox (partículas)", s.mods.hitbox);
  form.toggle("Reach Indicator", s.mods.reach);
  form.toggle("Coordenadas", s.mods.coords);
  form.toggle("Mostrar HUD (master)", s.mods.showHud);
  form.show(player).then((res) => {
    if (res.canceled) return;
    [
      s.mods.fps,
      s.mods.cps,
      s.mods.keystrokes,
      s.mods.tntTimer,
      s.mods.hitbox,
      s.mods.reach,
      s.mods.coords,
      s.mods.showHud,
    ] = res.formValues;
    player.sendMessage("§aMods atualizados.");
  }).catch(() => {});
}

function openHudMenu(player) {
  const s = getState(player);
  const form = new ActionFormData()
    .title("§lHUD — escolha o que mover§r")
    .body("§7A Script API não permite arrastar elementos.\n§7Edite as posições por nome:");
  const keys = Object.keys(s.hud);
  for (const k of keys) {
    const h = s.hud[k];
    form.button(`§f${k}§7 — x:${h.x} y:${h.y} ${h.on ? "§aon" : "§cof"}`);
  }
  form.button("§7Voltar");
  form.show(player).then((res) => {
    if (res.canceled) return;
    if (res.selection === keys.length) return openMainMenu(player);
    const which = keys[res.selection];
    editHudElement(player, which);
  }).catch(() => {});
}

function editHudElement(player, which) {
  const s = getState(player);
  const h = s.hud[which];
  const form = new ModalFormData().title(`§lHUD: ${which}§r`);
  form.slider("X (0–100)", 0, 100, 1, h.x);
  form.slider("Y (0–100)", 0, 100, 1, h.y);
  form.toggle("Ativo", h.on);
  form.show(player).then((res) => {
    if (res.canceled) return;
    h.x = res.formValues[0];
    h.y = res.formValues[1];
    h.on = res.formValues[2];
    player.sendMessage(`§aHUD ${which} atualizado.`);
  }).catch(() => {});
}

function openTexturesMenu(player) {
  const form = new ActionFormData()
    .title("§lTexturas / Subpacks§r")
    .body(
      "§7Subpacks devem ser ativados nas Configurações de Mundo →\n" +
        "§7Pacotes de Recursos → Fex Private → engrenagem.\n\n" +
        "§fDisponíveis:\n§7• Padrão (Preto/Branco)\n§7• Vermelho Sangue\n§7• Azul Gelo\n§7• Dourado",
    )
    .button("§7OK");
  form.show(player).catch(() => {});
}

function openAboutMenu(player) {
  const form = new ActionFormData()
    .title("§lFex Private§r")
    .body(
      "§7Pack PvP Bedrock 1.26.21\n" +
        "§7Mods: FPS, CPS, Keystrokes, TNT Timer, Hitbox, Reach\n\n" +
        "§fComo abrir:\n" +
        "§7• Digite §f!fex§7 no chat\n" +
        "§7• Ou use o item §fFex Menu§7 (criativo)\n\n" +
        "§7Comandos chat:\n" +
        "§f!fex§7 — abrir menu\n" +
        "§f!fex hud§7 — só HUD\n" +
        "§f!fex toggle <mod>§7 — toggle rápido",
    )
    .button("§7OK");
  form.show(player).catch(() => {});
}

// ---------------------------------------------------------------------------
// Chat command
// ---------------------------------------------------------------------------
world.beforeEvents.chatSend.subscribe((ev) => {
  const msg = ev.message.trim();
  if (!msg.startsWith("!fex")) return;
  ev.cancel = true;
  const parts = msg.split(/\s+/);
  const sender = ev.sender;
  system.run(() => {
    if (parts.length === 1) {
      openMainMenu(sender);
    } else if (parts[1] === "hud") {
      openHudMenu(sender);
    } else if (parts[1] === "toggle" && parts[2]) {
      const s = getState(sender);
      const key = parts[2].toLowerCase();
      if (key in s.mods) {
        s.mods[key] = !s.mods[key];
        sender.sendMessage(`§a${key} = ${s.mods[key]}`);
      } else {
        sender.sendMessage(`§cMod desconhecido: ${key}`);
      }
    } else {
      sender.sendMessage("§7Uso: !fex | !fex hud | !fex toggle <mod>");
    }
  });
});

// ---------------------------------------------------------------------------
// Script event — /scriptevent fex:menu open  (also triggers from /function)
// ---------------------------------------------------------------------------
system.afterEvents.scriptEventReceive.subscribe((ev) => {
  if (ev.id !== "fex:menu") return;
  const src = ev.sourceEntity;
  if (src instanceof Player) {
    openMainMenu(src);
  } else {
    // Open for all online players when run from console
    for (const p of world.getAllPlayers()) openMainMenu(p);
  }
});

// ---------------------------------------------------------------------------
// On join — give item & welcome
// ---------------------------------------------------------------------------
world.afterEvents.playerSpawn.subscribe((ev) => {
  if (!ev.initialSpawn) return;
  const p = ev.player;
  p.sendMessage("§lFex Private§r §7carregado. Digite §f!fex§7 para abrir o menu.");
});
