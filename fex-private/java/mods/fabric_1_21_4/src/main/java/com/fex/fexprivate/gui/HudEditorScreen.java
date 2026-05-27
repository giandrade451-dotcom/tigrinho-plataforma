package com.fex.fexprivate.gui;

import com.fex.fexprivate.FexPrivateClient;
import com.fex.fexprivate.config.FexConfig;
import net.minecraft.client.gui.DrawContext;
import net.minecraft.client.gui.screen.Screen;
import net.minecraft.client.gui.widget.ButtonWidget;
import net.minecraft.text.Text;

/**
 * Drag-to-position HUD editor. Click an element and drag it to reposition.
 */
public class HudEditorScreen extends Screen {
    private FexConfig.Pos dragging;
    private int dragOffX, dragOffY;

    public HudEditorScreen() {
        super(Text.literal("HUD Editor"));
    }

    @Override
    protected void init() {
        this.addDrawableChild(ButtonWidget.builder(Text.literal("Voltar"),
                btn -> this.client.setScreen(new FexMenuScreen()))
                .dimensions(this.width - 90, 10, 80, 20)
                .build());
    }

    @Override
    public boolean mouseClicked(double mx, double my, int btn) {
        if (super.mouseClicked(mx, my, btn)) return true;
        FexConfig c = FexPrivateClient.CONFIG;
        for (FexConfig.Pos p : new FexConfig.Pos[]{c.fpsPos, c.cpsPos, c.keysPos, c.tntPos, c.reachPos, c.coordsPos}) {
            if (mx >= p.x && mx <= p.x + 80 && my >= p.y && my <= p.y + 20) {
                dragging = p;
                dragOffX = (int) mx - p.x;
                dragOffY = (int) my - p.y;
                return true;
            }
        }
        return false;
    }

    @Override
    public boolean mouseDragged(double mx, double my, int btn, double dx, double dy) {
        if (dragging != null) {
            dragging.x = (int) mx - dragOffX;
            dragging.y = (int) my - dragOffY;
            return true;
        }
        return super.mouseDragged(mx, my, btn, dx, dy);
    }

    @Override
    public boolean mouseReleased(double mx, double my, int btn) {
        if (dragging != null) {
            dragging = null;
            FexPrivateClient.CONFIG.save();
            return true;
        }
        return super.mouseReleased(mx, my, btn);
    }

    @Override
    public void render(DrawContext ctx, int mouseX, int mouseY, float delta) {
        this.renderBackground(ctx, mouseX, mouseY, delta);
        FexConfig c = FexPrivateClient.CONFIG;
        drawBox(ctx, c.fpsPos, "FPS");
        drawBox(ctx, c.cpsPos, "CPS");
        drawBox(ctx, c.keysPos, "WASD");
        drawBox(ctx, c.tntPos, "TNT");
        drawBox(ctx, c.reachPos, "Reach");
        drawBox(ctx, c.coordsPos, "Coords");
        super.render(ctx, mouseX, mouseY, delta);
        ctx.drawCenteredTextWithShadow(this.textRenderer,
                Text.literal("Arraste os elementos para reposicionar"),
                this.width / 2, 16, 0xFFFFFFFF);
    }

    private void drawBox(DrawContext ctx, FexConfig.Pos p, String label) {
        ctx.fill(p.x, p.y, p.x + 60, p.y + 14, 0xAA000000);
        ctx.drawBorder(p.x, p.y, 60, 14, 0xFFFFFFFF);
        ctx.drawTextWithShadow(this.textRenderer, Text.literal(label), p.x + 4, p.y + 3, 0xFFFFFFFF);
    }
}
