package com.fex.fexprivate.hud;

import com.fex.fexprivate.FexPrivateClient;
import com.fex.fexprivate.config.FexConfig;
import com.fex.fexprivate.mods.CpsMod;
import com.fex.fexprivate.mods.FpsMod;
import com.fex.fexprivate.mods.KeystrokesMod;
import com.fex.fexprivate.mods.ReachMod;
import com.fex.fexprivate.mods.TntTimerMod;
import net.minecraft.client.MinecraftClient;
import net.minecraft.client.gui.DrawContext;
import net.minecraft.client.render.RenderTickCounter;
import net.minecraft.text.Text;
import net.minecraft.util.Formatting;

public class HudRenderer {
    public static void render(DrawContext ctx, RenderTickCounter tick) {
        FexPrivateClient.CONFIG.toString(); // ensure loaded
        FpsMod.frame();
        FexConfig c = FexPrivateClient.CONFIG;
        if (!c.masterShowHud) return;
        MinecraftClient mc = MinecraftClient.getInstance();
        if (mc.options.debugEnabled) return;

        if (c.fps) {
            drawLabel(ctx, c.fpsPos.x, c.fpsPos.y, Text.literal(FpsMod.fps + " fps").formatted(Formatting.GREEN));
        }
        if (c.cps) {
            drawLabel(ctx, c.cpsPos.x, c.cpsPos.y,
                    Text.literal("L " + CpsMod.leftCps + "  R " + CpsMod.rightCps + " cps")
                            .formatted(Formatting.YELLOW));
        }
        if (c.keystrokes) {
            int x = c.keysPos.x;
            int y = c.keysPos.y;
            drawKey(ctx, x + 14, y, "W", KeystrokesMod.w);
            drawKey(ctx, x, y + 12, "A", KeystrokesMod.a);
            drawKey(ctx, x + 14, y + 12, "S", KeystrokesMod.s);
            drawKey(ctx, x + 28, y + 12, "D", KeystrokesMod.d);
            drawKey(ctx, x, y + 24, "LMB", KeystrokesMod.lmb);
            drawKey(ctx, x + 22, y + 24, "RMB", KeystrokesMod.rmb);
        }
        if (c.reach && ReachMod.currentReach > 0) {
            drawLabel(ctx, c.reachPos.x, c.reachPos.y,
                    Text.literal(String.format("%.2fm reach", ReachMod.currentReach))
                            .formatted(Formatting.AQUA));
        }
        if (c.coords && mc.player != null) {
            var p = mc.player.getPos();
            drawLabel(ctx, c.coordsPos.x, c.coordsPos.y,
                    Text.literal(String.format("%.1f %.1f %.1f", p.x, p.y, p.z))
                            .formatted(Formatting.GRAY));
        }
        if (c.tntTimer && TntTimerMod.fuseTicks >= 0) {
            drawLabel(ctx, c.tntPos.x, c.tntPos.y,
                    Text.literal(String.format("TNT %.1fs (%.1fm)",
                            TntTimerMod.fuseTicks / 20.0, TntTimerMod.distance))
                            .formatted(Formatting.RED));
        }
    }

    private static void drawLabel(DrawContext ctx, int x, int y, Text text) {
        ctx.fill(x - 1, y - 1, x + MinecraftClient.getInstance().textRenderer.getWidth(text) + 1, y + 9, 0x80000000);
        ctx.drawTextWithShadow(MinecraftClient.getInstance().textRenderer, text, x, y, 0xFFFFFFFF);
    }

    private static void drawKey(DrawContext ctx, int x, int y, String label, boolean pressed) {
        int bg = pressed ? 0xFFFFFFFF : 0x60000000;
        int fg = pressed ? 0xFF000000 : 0xFFFFFFFF;
        ctx.fill(x, y, x + 12, y + 11, bg);
        ctx.drawTextWithShadow(MinecraftClient.getInstance().textRenderer,
                Text.literal(label), x + 2, y + 2, fg);
    }
}
