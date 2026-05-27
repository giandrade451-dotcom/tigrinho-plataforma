package com.fex.fexprivate.gui;

import com.fex.fexprivate.FexPrivateClient;
import com.fex.fexprivate.config.FexConfig;
import net.minecraft.client.gui.DrawContext;
import net.minecraft.client.gui.screen.Screen;
import net.minecraft.client.gui.widget.ButtonWidget;
import net.minecraft.text.Text;

public class FexMenuScreen extends Screen {
    public FexMenuScreen() {
        super(Text.literal("Fex Private"));
    }

    @Override
    protected void init() {
        FexConfig c = FexPrivateClient.CONFIG;
        int x = this.width / 2 - 100;
        int y = 40;
        int dy = 24;

        addToggle(c, "FPS",         x, y,         () -> c.fps,         v -> c.fps = v);
        addToggle(c, "CPS",         x, y + dy,    () -> c.cps,         v -> c.cps = v);
        addToggle(c, "Keystrokes",  x, y + dy*2,  () -> c.keystrokes,  v -> c.keystrokes = v);
        addToggle(c, "TNT Timer",   x, y + dy*3,  () -> c.tntTimer,    v -> c.tntTimer = v);
        addToggle(c, "Hitbox",      x, y + dy*4,  () -> c.hitbox,      v -> c.hitbox = v);
        addToggle(c, "Reach",       x, y + dy*5,  () -> c.reach,       v -> c.reach = v);
        addToggle(c, "Coords",      x, y + dy*6,  () -> c.coords,      v -> c.coords = v);
        addToggle(c, "Mostrar HUD", x, y + dy*7,  () -> c.masterShowHud, v -> c.masterShowHud = v);

        this.addDrawableChild(ButtonWidget.builder(Text.literal("Editar HUD"),
                btn -> this.client.setScreen(new HudEditorScreen()))
                .dimensions(x, y + dy*8 + 8, 200, 20)
                .build());

        this.addDrawableChild(ButtonWidget.builder(Text.literal("Salvar e fechar"),
                btn -> { c.save(); this.close(); })
                .dimensions(x, y + dy*9 + 8, 200, 20)
                .build());
    }

    interface BoolGetter { boolean get(); }
    interface BoolSetter { void set(boolean v); }

    private void addToggle(FexConfig c, String label, int x, int y,
                           BoolGetter getter, BoolSetter setter) {
        this.addDrawableChild(ButtonWidget.builder(
                Text.literal(label + ": " + (getter.get() ? "§aON" : "§cOFF")),
                btn -> {
                    setter.set(!getter.get());
                    btn.setMessage(Text.literal(label + ": " + (getter.get() ? "§aON" : "§cOFF")));
                    c.save();
                }).dimensions(x, y, 200, 20).build());
    }

    @Override
    public void render(DrawContext ctx, int mouseX, int mouseY, float delta) {
        this.renderBackground(ctx, mouseX, mouseY, delta);
        super.render(ctx, mouseX, mouseY, delta);
        ctx.drawCenteredTextWithShadow(this.textRenderer,
                Text.literal("§lFex Private§r").formatted(net.minecraft.util.Formatting.WHITE),
                this.width / 2, 16, 0xFFFFFFFF);
    }
}
