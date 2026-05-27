package com.fex.fexprivate.mods;

import net.minecraft.client.MinecraftClient;
import net.minecraft.client.option.KeyBinding;

public class KeystrokesMod {
    public static boolean w, a, s, d, jump, sneak, lmb, rmb;

    public static void tick(MinecraftClient client) {
        if (client.options == null) return;
        w = client.options.forwardKey.isPressed();
        a = client.options.leftKey.isPressed();
        s = client.options.backKey.isPressed();
        d = client.options.rightKey.isPressed();
        jump = client.options.jumpKey.isPressed();
        sneak = client.options.sneakKey.isPressed();
        lmb = client.options.attackKey.isPressed();
        rmb = client.options.useKey.isPressed();
    }
}
