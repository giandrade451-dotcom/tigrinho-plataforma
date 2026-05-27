package com.fex.fexprivate.gui;

import com.fex.fexprivate.FexMod;
import com.fex.fexprivate.config.FexConfig;

import net.minecraft.client.gui.Gui;
import net.minecraft.client.gui.GuiButton;
import net.minecraft.client.gui.GuiScreen;

public class HudEditorScreen extends GuiScreen {
    private int draggingId = -1;
    private int dragOffX, dragOffY;

    private static class Box {
        int x, y;
        String label;
        Runnable applyX; // not used; using id mapping instead
    }

    @Override
    public void initGui() {
        buttonList.clear();
        buttonList.add(new GuiButton(99, this.width - 90, 10, 80, 20, "Voltar"));
    }

    @Override
    protected void actionPerformed(GuiButton b) {
        if (b.id == 99) this.mc.displayGuiScreen(new FexMenuScreen());
    }

    @Override
    protected void mouseClicked(int mx, int my, int btn) {
        FexConfig c = FexMod.CONFIG;
        int[][] positions = {
            {0, c.fpsX, c.fpsY},
            {1, c.cpsX, c.cpsY},
            {2, c.keysX, c.keysY},
            {3, c.tntX, c.tntY},
            {4, c.reachX, c.reachY},
            {5, c.coordsX, c.coordsY},
        };
        for (int[] p : positions) {
            if (mx >= p[1] && mx <= p[1] + 60 && my >= p[2] && my <= p[2] + 14) {
                draggingId = p[0];
                dragOffX = mx - p[1];
                dragOffY = my - p[2];
                return;
            }
        }
        try { super.mouseClicked(mx, my, btn); } catch (Exception e) {}
    }

    @Override
    protected void mouseClickMove(int mx, int my, int btn, long held) {
        if (draggingId < 0) return;
        FexConfig c = FexMod.CONFIG;
        int nx = mx - dragOffX;
        int ny = my - dragOffY;
        switch (draggingId) {
            case 0: c.fpsX = nx; c.fpsY = ny; break;
            case 1: c.cpsX = nx; c.cpsY = ny; break;
            case 2: c.keysX = nx; c.keysY = ny; break;
            case 3: c.tntX = nx; c.tntY = ny; break;
            case 4: c.reachX = nx; c.reachY = ny; break;
            case 5: c.coordsX = nx; c.coordsY = ny; break;
        }
    }

    @Override
    protected void mouseReleased(int mx, int my, int btn) {
        if (draggingId >= 0) {
            FexMod.CONFIG.save();
            draggingId = -1;
        }
    }

    @Override
    public void drawScreen(int mx, int my, float pt) {
        drawDefaultBackground();
        FexConfig c = FexMod.CONFIG;
        drawBox(c.fpsX, c.fpsY, "FPS");
        drawBox(c.cpsX, c.cpsY, "CPS");
        drawBox(c.keysX, c.keysY, "WASD");
        drawBox(c.tntX, c.tntY, "TNT");
        drawBox(c.reachX, c.reachY, "Reach");
        drawBox(c.coordsX, c.coordsY, "Coords");
        drawCenteredString(fontRendererObj,
                "Arraste os elementos para reposicionar",
                this.width / 2, 16, 0xFFFFFFFF);
        super.drawScreen(mx, my, pt);
    }

    private void drawBox(int x, int y, String label) {
        Gui.drawRect(x, y, x + 60, y + 14, 0xAA000000);
        Gui.drawRect(x, y, x + 60, y + 1, 0xFFFFFFFF);
        Gui.drawRect(x, y + 13, x + 60, y + 14, 0xFFFFFFFF);
        Gui.drawRect(x, y, x + 1, y + 14, 0xFFFFFFFF);
        Gui.drawRect(x + 59, y, x + 60, y + 14, 0xFFFFFFFF);
        fontRendererObj.drawStringWithShadow(label, x + 4, y + 3, 0xFFFFFFFF);
    }

    @Override
    public boolean doesGuiPauseGame() { return false; }
}
