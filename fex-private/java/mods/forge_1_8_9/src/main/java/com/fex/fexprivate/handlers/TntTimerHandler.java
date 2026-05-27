package com.fex.fexprivate.handlers;

import com.fex.fexprivate.FexMod;

import net.minecraft.client.Minecraft;
import net.minecraft.entity.Entity;
import net.minecraft.entity.item.EntityTNTPrimed;
import net.minecraftforge.fml.common.eventhandler.SubscribeEvent;
import net.minecraftforge.fml.common.gameevent.TickEvent;

import java.util.List;

public class TntTimerHandler {
    public static int fuse = -1;
    public static double distance = -1;

    @SubscribeEvent
    public void onTick(TickEvent.ClientTickEvent e) {
        if (e.phase != TickEvent.Phase.END) return;
        if (FexMod.CONFIG == null || !FexMod.CONFIG.tntTimer) {
            fuse = -1;
            return;
        }
        Minecraft mc = Minecraft.getMinecraft();
        if (mc.theWorld == null || mc.thePlayer == null) return;

        EntityTNTPrimed nearest = null;
        double best = Double.MAX_VALUE;
        List<Entity> ents = mc.theWorld.loadedEntityList;
        for (int i = 0; i < ents.size(); i++) {
            Entity ent = ents.get(i);
            if (!(ent instanceof EntityTNTPrimed)) continue;
            double d = mc.thePlayer.getDistanceSqToEntity(ent);
            if (d < best) {
                best = d;
                nearest = (EntityTNTPrimed) ent;
            }
        }
        if (nearest != null) {
            fuse = nearest.getFuse();
            distance = Math.sqrt(best);
        } else {
            fuse = -1;
            distance = -1;
        }
    }
}
