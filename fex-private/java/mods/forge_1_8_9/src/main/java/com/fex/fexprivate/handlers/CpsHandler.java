package com.fex.fexprivate.handlers;

import net.minecraft.client.Minecraft;
import net.minecraftforge.fml.common.eventhandler.SubscribeEvent;
import net.minecraftforge.fml.common.gameevent.TickEvent;

import org.lwjgl.input.Mouse;

import java.util.ArrayDeque;
import java.util.Deque;

public class CpsHandler {
    public static int leftCps = 0;
    public static int rightCps = 0;
    private static final Deque<Long> LEFT = new ArrayDeque<Long>();
    private static final Deque<Long> RIGHT = new ArrayDeque<Long>();
    private boolean leftPrev = false;
    private boolean rightPrev = false;

    @SubscribeEvent
    public void onTick(TickEvent.ClientTickEvent e) {
        if (e.phase != TickEvent.Phase.END) return;
        boolean leftNow = Mouse.isButtonDown(0);
        boolean rightNow = Mouse.isButtonDown(1);
        long now = System.currentTimeMillis();
        if (leftNow && !leftPrev) LEFT.add(now);
        if (rightNow && !rightPrev) RIGHT.add(now);
        leftPrev = leftNow;
        rightPrev = rightNow;
        prune(LEFT, now);
        prune(RIGHT, now);
        leftCps = LEFT.size();
        rightCps = RIGHT.size();
    }

    private void prune(Deque<Long> q, long now) {
        while (!q.isEmpty() && now - q.peek() > 1000L) q.poll();
    }
}
