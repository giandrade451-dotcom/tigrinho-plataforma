package com.fex.fexprivate.mods;

import com.fex.fexprivate.FexPrivateClient;
import net.minecraft.client.MinecraftClient;
import net.minecraft.util.hit.HitResult;

public class ReachMod {
    public static double currentReach = 0;

    public static void tick(MinecraftClient client) {
        if (!FexPrivateClient.CONFIG.reach) {
            currentReach = 0;
            return;
        }
        if (client.player == null) {
            currentReach = 0;
            return;
        }
        HitResult hit = client.crosshairTarget;
        if (hit != null && hit.getType() != HitResult.Type.MISS) {
            currentReach = Math.sqrt(client.player.getEyePos().squaredDistanceTo(hit.getPos()));
        } else {
            currentReach = 0;
        }
    }
}
