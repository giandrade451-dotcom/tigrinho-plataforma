package com.fex.fexprivate.mixin;

import com.fex.fexprivate.FexPrivateClient;
import net.minecraft.client.render.entity.EntityRenderDispatcher;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.injection.At;
import org.spongepowered.asm.mixin.injection.Inject;
import org.spongepowered.asm.mixin.injection.callback.CallbackInfoReturnable;

/**
 * Force-enables vanilla hitbox rendering whenever the Fex Hitbox mod is on,
 * regardless of F3+B state.
 */
@Mixin(EntityRenderDispatcher.class)
public class EntityRendererMixin {
    @Inject(method = "shouldRenderHitboxes", at = @At("RETURN"), cancellable = true)
    private void fex$forceHitbox(CallbackInfoReturnable<Boolean> cir) {
        if (FexPrivateClient.CONFIG != null && FexPrivateClient.CONFIG.hitbox) {
            cir.setReturnValue(true);
        }
    }
}
