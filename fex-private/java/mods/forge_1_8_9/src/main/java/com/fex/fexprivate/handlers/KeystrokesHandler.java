package com.fex.fexprivate.handlers;

import net.minecraft.client.Minecraft;
import net.minecraft.client.settings.GameSettings;
import net.minecraftforge.fml.common.eventhandler.SubscribeEvent;
import net.minecraftforge.fml.common.gameevent.TickEvent;

public class KeystrokesHandler {
    public static boolean w, a, s, d, jump, sneak, lmb, rmb;

    @SubscribeEvent
    public void onTick(TickEvent.ClientTickEvent e) {
        if (e.phase != TickEvent.Phase.END) return;
        GameSettings g = Minecraft.getMinecraft().gameSettings;
        w = g.keyBindForward.isKeyDown();
        a = g.keyBindLeft.isKeyDown();
        s = g.keyBindBack.isKeyDown();
        d = g.keyBindRight.isKeyDown();
        jump = g.keyBindJump.isKeyDown();
        sneak = g.keyBindSneak.isKeyDown();
        lmb = g.keyBindAttack.isKeyDown();
        rmb = g.keyBindUseItem.isKeyDown();
    }
}
