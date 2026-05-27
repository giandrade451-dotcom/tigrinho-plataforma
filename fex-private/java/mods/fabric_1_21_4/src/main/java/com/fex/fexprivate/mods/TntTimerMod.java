package com.fex.fexprivate.mods;

import com.fex.fexprivate.FexPrivateClient;
import net.minecraft.client.MinecraftClient;
import net.minecraft.entity.Entity;
import net.minecraft.entity.TntEntity;

public class TntTimerMod {
    public static int fuseTicks = -1;
    public static double distance = -1;

    public static void tick(MinecraftClient client) {
        if (!FexPrivateClient.CONFIG.tntTimer) {
            fuseTicks = -1;
            return;
        }
        if (client.world == null || client.player == null) return;
        TntEntity nearest = null;
        double best = Double.MAX_VALUE;
        for (Entity e : client.world.getEntities()) {
            if (!(e instanceof TntEntity tnt)) continue;
            double d = client.player.squaredDistanceTo(e);
            if (d < best) {
                best = d;
                nearest = tnt;
            }
        }
        if (nearest != null) {
            fuseTicks = nearest.getFuse();
            distance = Math.sqrt(best);
        } else {
            fuseTicks = -1;
            distance = -1;
        }
    }
}
