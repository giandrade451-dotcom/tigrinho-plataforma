package com.fex.fexprivate.handlers;

import com.fex.fexprivate.FexMod;
import com.fex.fexprivate.config.FexConfig;

import net.minecraft.client.Minecraft;
import net.minecraft.client.gui.FontRenderer;
import net.minecraft.client.gui.Gui;
import net.minecraft.client.gui.ScaledResolution;
import net.minecraft.entity.player.EntityPlayer;
import net.minecraft.util.MovingObjectPosition;
import net.minecraftforge.client.event.RenderGameOverlayEvent;
import net.minecraftforge.fml.common.eventhandler.SubscribeEvent;

public class HudHandler {
    private long lastFpsTime = System.currentTimeMillis();
    private int frameCount = 0;
    private int fps = 0;

    @SubscribeEvent
    public void onRender(RenderGameOverlayEvent.Post e) {
        if (e.type != RenderGameOverlayEvent.ElementType.ALL) return;
        FexConfig c = FexMod.CONFIG;
        if (c == null || !c.masterShowHud) return;
        Minecraft mc = Minecraft.getMinecraft();
        FontRenderer fr = mc.fontRendererObj;
        if (mc.thePlayer == null || mc.gameSettings.showDebugInfo) return;

        // FPS
        frameCount++;
        long now = System.currentTimeMillis();
        if (now - lastFpsTime >= 1000) {
            fps = frameCount;
            frameCount = 0;
            lastFpsTime = now;
        }

        if (c.fps) {
            drawLabel(fr, c.fpsX, c.fpsY, "§a" + fps + "§7 fps");
        }
        if (c.cps) {
            drawLabel(fr, c.cpsX, c.cpsY, "§eL " + CpsHandler.leftCps + "  R " + CpsHandler.rightCps + " cps");
        }
        if (c.keystrokes) {
            drawKey(fr, c.keysX + 14, c.keysY,      "W", KeystrokesHandler.w);
            drawKey(fr, c.keysX,      c.keysY + 12, "A", KeystrokesHandler.a);
            drawKey(fr, c.keysX + 14, c.keysY + 12, "S", KeystrokesHandler.s);
            drawKey(fr, c.keysX + 28, c.keysY + 12, "D", KeystrokesHandler.d);
            drawKey(fr, c.keysX,      c.keysY + 24, "LMB", KeystrokesHandler.lmb);
            drawKey(fr, c.keysX + 22, c.keysY + 24, "RMB", KeystrokesHandler.rmb);
        }
        if (c.coords) {
            EntityPlayer p = mc.thePlayer;
            drawLabel(fr, c.coordsX, c.coordsY,
                    String.format("§7%.1f %.1f %.1f", p.posX, p.posY, p.posZ));
        }
        if (c.reach) {
            MovingObjectPosition mop = mc.objectMouseOver;
            if (mop != null && mop.typeOfHit != MovingObjectPosition.MovingObjectType.MISS) {
                double dx = mop.hitVec.xCoord - mc.thePlayer.posX;
                double dy = mop.hitVec.yCoord - (mc.thePlayer.posY + mc.thePlayer.getEyeHeight());
                double dz = mop.hitVec.zCoord - mc.thePlayer.posZ;
                double dist = Math.sqrt(dx*dx + dy*dy + dz*dz);
                drawLabel(fr, c.reachX, c.reachY, String.format("§b%.2fm§7 reach", dist));
            }
        }
        if (c.tntTimer && TntTimerHandler.fuse >= 0) {
            drawLabel(fr, c.tntX, c.tntY,
                    String.format("§cTNT §7%.1fs (%.1fm)",
                            TntTimerHandler.fuse / 20.0, TntTimerHandler.distance));
        }
    }

    private void drawLabel(FontRenderer fr, int x, int y, String text) {
        Gui.drawRect(x - 1, y - 1, x + fr.getStringWidth(text) + 1, y + 9, 0x80000000);
        fr.drawStringWithShadow(text, x, y, 0xFFFFFF);
    }

    private void drawKey(FontRenderer fr, int x, int y, String label, boolean pressed) {
        int bg = pressed ? 0xFFFFFFFF : 0x60000000;
        int fg = pressed ? 0x000000 : 0xFFFFFF;
        Gui.drawRect(x, y, x + 12, y + 11, bg);
        fr.drawStringWithShadow(label, x + 2, y + 2, fg);
    }
}
