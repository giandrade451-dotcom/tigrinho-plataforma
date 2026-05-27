package com.fex.fexprivate.mods;

import net.minecraft.client.MinecraftClient;
import net.minecraft.client.util.InputUtil;
import org.lwjgl.glfw.GLFW;

import java.util.ArrayDeque;
import java.util.Deque;

public class CpsMod {
    public static int leftCps = 0;
    public static int rightCps = 0;
    private static final Deque<Long> LEFT_CLICKS = new ArrayDeque<>();
    private static final Deque<Long> RIGHT_CLICKS = new ArrayDeque<>();

    private static boolean leftPrev = false;
    private static boolean rightPrev = false;

    public static void tick(MinecraftClient client) {
        if (client.getWindow() == null) return;
        long handle = client.getWindow().getHandle();
        boolean leftNow = GLFW.glfwGetMouseButton(handle, GLFW.GLFW_MOUSE_BUTTON_LEFT) == GLFW.GLFW_PRESS;
        boolean rightNow = GLFW.glfwGetMouseButton(handle, GLFW.GLFW_MOUSE_BUTTON_RIGHT) == GLFW.GLFW_PRESS;
        long now = System.currentTimeMillis();

        if (leftNow && !leftPrev) LEFT_CLICKS.add(now);
        if (rightNow && !rightPrev) RIGHT_CLICKS.add(now);
        leftPrev = leftNow;
        rightPrev = rightNow;

        prune(LEFT_CLICKS, now);
        prune(RIGHT_CLICKS, now);
        leftCps = LEFT_CLICKS.size();
        rightCps = RIGHT_CLICKS.size();
    }

    private static void prune(Deque<Long> q, long now) {
        while (!q.isEmpty() && now - q.peek() > 1000L) q.poll();
    }
}
