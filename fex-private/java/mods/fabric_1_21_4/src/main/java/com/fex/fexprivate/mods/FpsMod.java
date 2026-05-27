package com.fex.fexprivate.mods;

import net.minecraft.client.MinecraftClient;

public class FpsMod {
    public static int fps = 0;
    private static int frameCount = 0;
    private static long lastTime = System.currentTimeMillis();

    public static void tick(MinecraftClient client) {
        frameCount++;
        long now = System.currentTimeMillis();
        if (now - lastTime >= 1000) {
            fps = frameCount;
            frameCount = 0;
            lastTime = now;
        }
        // For accurate fps, we'd hook into the render thread — see HudRenderer.
    }

    /** Called from HudRenderer once per frame (accurate FPS). */
    public static void frame() {
        frameCount++;
        long now = System.currentTimeMillis();
        if (now - lastTime >= 1000) {
            fps = frameCount;
            frameCount = 0;
            lastTime = now;
        }
    }
}
