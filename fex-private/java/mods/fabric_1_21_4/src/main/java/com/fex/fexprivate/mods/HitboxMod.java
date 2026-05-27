package com.fex.fexprivate.mods;

import com.fex.fexprivate.FexPrivateClient;
import net.minecraft.client.MinecraftClient;

public class HitboxMod {
    public static boolean enabled = false;

    public static void tick(MinecraftClient client) {
        enabled = FexPrivateClient.CONFIG.hitbox;
        // The actual hitbox rendering is forced via a mixin into
        // EntityRenderDispatcher#shouldRenderHitboxes — see EntityRendererMixin.
        // When enabled, vanilla F3+B hitbox rendering is force-enabled.
    }
}
