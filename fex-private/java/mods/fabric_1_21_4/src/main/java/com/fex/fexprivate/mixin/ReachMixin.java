package com.fex.fexprivate.mixin;

import org.spongepowered.asm.mixin.Mixin;
import net.minecraft.client.MinecraftClient;

/**
 * Placeholder mixin slot — reach indicator does NOT modify actual attack reach
 * (that would be detected as a hack by anti-cheat). It only DISPLAYS distance
 * to the crosshair target via ReachMod.
 *
 * If you want to extend max attack range (NOT recommended — flagged as cheat
 * on virtually every server with anti-cheat), this is where you would hook
 * MinecraftClient.doAttack or PlayerInteractionManager.
 */
@Mixin(MinecraftClient.class)
public class ReachMixin {
}
