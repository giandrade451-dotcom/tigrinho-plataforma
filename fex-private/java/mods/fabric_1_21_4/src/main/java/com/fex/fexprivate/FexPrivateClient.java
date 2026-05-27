package com.fex.fexprivate;

import net.fabricmc.api.ClientModInitializer;
import net.fabricmc.fabric.api.client.event.lifecycle.v1.ClientTickEvents;
import net.fabricmc.fabric.api.client.keybinding.v1.KeyBindingHelper;
import net.fabricmc.fabric.api.client.rendering.v1.HudRenderCallback;
import net.minecraft.client.MinecraftClient;
import net.minecraft.client.option.KeyBinding;
import net.minecraft.client.util.InputUtil;
import org.lwjgl.glfw.GLFW;

import com.fex.fexprivate.config.FexConfig;
import com.fex.fexprivate.gui.FexMenuScreen;
import com.fex.fexprivate.hud.HudRenderer;
import com.fex.fexprivate.mods.CpsMod;
import com.fex.fexprivate.mods.FpsMod;
import com.fex.fexprivate.mods.HitboxMod;
import com.fex.fexprivate.mods.KeystrokesMod;
import com.fex.fexprivate.mods.ReachMod;
import com.fex.fexprivate.mods.TntTimerMod;

public class FexPrivateClient implements ClientModInitializer {
    public static final String MOD_ID = "fexprivate";
    public static FexConfig CONFIG;
    public static KeyBinding OPEN_MENU;

    @Override
    public void onInitializeClient() {
        CONFIG = FexConfig.load();

        OPEN_MENU = KeyBindingHelper.registerKeyBinding(new KeyBinding(
                "key.fexprivate.menu",
                InputUtil.Type.KEYSYM,
                GLFW.GLFW_KEY_RIGHT_SHIFT,
                "category.fexprivate"
        ));

        // Per-tick mod updates
        ClientTickEvents.END_CLIENT_TICK.register(client -> {
            FpsMod.tick(client);
            CpsMod.tick(client);
            KeystrokesMod.tick(client);
            TntTimerMod.tick(client);
            HitboxMod.tick(client);
            ReachMod.tick(client);
            while (OPEN_MENU.wasPressed()) {
                client.setScreen(new FexMenuScreen());
            }
        });

        // HUD rendering
        HudRenderCallback.EVENT.register(HudRenderer::render);
    }
}
