package com.fex.fexprivate;

import com.fex.fexprivate.config.FexConfig;
import com.fex.fexprivate.gui.FexMenuScreen;
import com.fex.fexprivate.handlers.CpsHandler;
import com.fex.fexprivate.handlers.HudHandler;
import com.fex.fexprivate.handlers.KeystrokesHandler;
import com.fex.fexprivate.handlers.TntTimerHandler;

import net.minecraft.client.Minecraft;
import net.minecraft.client.settings.KeyBinding;
import net.minecraftforge.client.ClientCommandHandler;
import net.minecraftforge.fml.client.registry.ClientRegistry;
import net.minecraftforge.fml.common.Mod;
import net.minecraftforge.fml.common.Mod.EventHandler;
import net.minecraftforge.fml.common.event.FMLInitializationEvent;
import net.minecraftforge.fml.common.event.FMLPreInitializationEvent;
import net.minecraftforge.fml.common.eventhandler.SubscribeEvent;
import net.minecraftforge.fml.common.gameevent.InputEvent;
import net.minecraftforge.fml.common.gameevent.TickEvent;
import net.minecraftforge.common.MinecraftForge;

import org.lwjgl.input.Keyboard;

@Mod(modid = FexMod.MODID, name = "Fex Private", version = "1.0.0", clientSideOnly = true)
public class FexMod {
    public static final String MODID = "fexprivate";

    public static FexConfig CONFIG;
    public static KeyBinding openMenuKey;

    @EventHandler
    public void preInit(FMLPreInitializationEvent e) {
        CONFIG = FexConfig.load(e.getSuggestedConfigurationFile());
    }

    @EventHandler
    public void init(FMLInitializationEvent e) {
        openMenuKey = new KeyBinding("Fex Menu", Keyboard.KEY_RSHIFT, "Fex Private");
        ClientRegistry.registerKeyBinding(openMenuKey);
        MinecraftForge.EVENT_BUS.register(this);
        MinecraftForge.EVENT_BUS.register(new HudHandler());
        MinecraftForge.EVENT_BUS.register(new CpsHandler());
        MinecraftForge.EVENT_BUS.register(new KeystrokesHandler());
        MinecraftForge.EVENT_BUS.register(new TntTimerHandler());
    }

    @SubscribeEvent
    public void onKey(InputEvent.KeyInputEvent e) {
        if (openMenuKey.isPressed()) {
            Minecraft.getMinecraft().displayGuiScreen(new FexMenuScreen());
        }
    }
}
