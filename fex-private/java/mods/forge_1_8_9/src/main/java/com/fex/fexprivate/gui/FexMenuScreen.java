package com.fex.fexprivate.gui;

import com.fex.fexprivate.FexMod;
import com.fex.fexprivate.config.FexConfig;

import net.minecraft.client.gui.GuiButton;
import net.minecraft.client.gui.GuiScreen;

import java.io.IOException;

public class FexMenuScreen extends GuiScreen {
    private FexConfig c;

    @Override
    public void initGui() {
        c = FexMod.CONFIG;
        int x = this.width / 2 - 100;
        int y = 40;
        int dy = 24;
        buttonList.clear();
        buttonList.add(new GuiButton(0, x, y,            200, 20, "FPS: " + onoff(c.fps)));
        buttonList.add(new GuiButton(1, x, y + dy,       200, 20, "CPS: " + onoff(c.cps)));
        buttonList.add(new GuiButton(2, x, y + dy*2,     200, 20, "Keystrokes: " + onoff(c.keystrokes)));
        buttonList.add(new GuiButton(3, x, y + dy*3,     200, 20, "TNT Timer: " + onoff(c.tntTimer)));
        buttonList.add(new GuiButton(4, x, y + dy*4,     200, 20, "Hitbox: " + onoff(c.hitbox)));
        buttonList.add(new GuiButton(5, x, y + dy*5,     200, 20, "Reach: " + onoff(c.reach)));
        buttonList.add(new GuiButton(6, x, y + dy*6,     200, 20, "Coords: " + onoff(c.coords)));
        buttonList.add(new GuiButton(7, x, y + dy*7,     200, 20, "Mostrar HUD: " + onoff(c.masterShowHud)));
        buttonList.add(new GuiButton(8, x, y + dy*8 + 8, 200, 20, "Editar HUD"));
        buttonList.add(new GuiButton(9, x, y + dy*9 + 8, 200, 20, "Salvar e fechar"));
    }

    private String onoff(boolean v) { return v ? "§aON" : "§cOFF"; }

    @Override
    protected void actionPerformed(GuiButton b) throws IOException {
        switch (b.id) {
            case 0: c.fps = !c.fps; break;
            case 1: c.cps = !c.cps; break;
            case 2: c.keystrokes = !c.keystrokes; break;
            case 3: c.tntTimer = !c.tntTimer; break;
            case 4: c.hitbox = !c.hitbox; break;
            case 5: c.reach = !c.reach; break;
            case 6: c.coords = !c.coords; break;
            case 7: c.masterShowHud = !c.masterShowHud; break;
            case 8: this.mc.displayGuiScreen(new HudEditorScreen()); return;
            case 9: c.save(); this.mc.displayGuiScreen(null); return;
        }
        c.save();
        initGui(); // refresh labels
    }

    @Override
    public void drawScreen(int mx, int my, float pt) {
        drawDefaultBackground();
        drawCenteredString(fontRendererObj, "§lFex Private§r", this.width / 2, 16, 0xFFFFFFFF);
        super.drawScreen(mx, my, pt);
    }

    @Override
    public boolean doesGuiPauseGame() { return false; }
}
