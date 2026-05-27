package com.fex.fexprivate.config;

import net.minecraftforge.common.config.Configuration;

import java.io.File;

public class FexConfig {
    public boolean fps = true;
    public boolean cps = true;
    public boolean keystrokes = true;
    public boolean tntTimer = true;
    public boolean hitbox = false;
    public boolean reach = true;
    public boolean coords = true;
    public boolean masterShowHud = true;

    public int fpsX = 2, fpsY = 2;
    public int cpsX = 2, cpsY = 12;
    public int keysX = 2, keysY = 22;
    public int tntX = 90, tntY = 2;
    public int reachX = 2, reachY = 60;
    public int coordsX = 2, coordsY = 70;

    private transient Configuration cfg;

    public static FexConfig load(File file) {
        FexConfig c = new FexConfig();
        c.cfg = new Configuration(file);
        c.cfg.load();
        c.fps = c.cfg.getBoolean("fps", "mods", c.fps, "");
        c.cps = c.cfg.getBoolean("cps", "mods", c.cps, "");
        c.keystrokes = c.cfg.getBoolean("keystrokes", "mods", c.keystrokes, "");
        c.tntTimer = c.cfg.getBoolean("tntTimer", "mods", c.tntTimer, "");
        c.hitbox = c.cfg.getBoolean("hitbox", "mods", c.hitbox, "");
        c.reach = c.cfg.getBoolean("reach", "mods", c.reach, "");
        c.coords = c.cfg.getBoolean("coords", "mods", c.coords, "");
        c.masterShowHud = c.cfg.getBoolean("masterShowHud", "mods", c.masterShowHud, "");
        c.fpsX = c.cfg.getInt("fpsX", "hud", c.fpsX, -10000, 10000, "");
        c.fpsY = c.cfg.getInt("fpsY", "hud", c.fpsY, -10000, 10000, "");
        c.cpsX = c.cfg.getInt("cpsX", "hud", c.cpsX, -10000, 10000, "");
        c.cpsY = c.cfg.getInt("cpsY", "hud", c.cpsY, -10000, 10000, "");
        c.keysX = c.cfg.getInt("keysX", "hud", c.keysX, -10000, 10000, "");
        c.keysY = c.cfg.getInt("keysY", "hud", c.keysY, -10000, 10000, "");
        c.tntX = c.cfg.getInt("tntX", "hud", c.tntX, -10000, 10000, "");
        c.tntY = c.cfg.getInt("tntY", "hud", c.tntY, -10000, 10000, "");
        c.reachX = c.cfg.getInt("reachX", "hud", c.reachX, -10000, 10000, "");
        c.reachY = c.cfg.getInt("reachY", "hud", c.reachY, -10000, 10000, "");
        c.coordsX = c.cfg.getInt("coordsX", "hud", c.coordsX, -10000, 10000, "");
        c.coordsY = c.cfg.getInt("coordsY", "hud", c.coordsY, -10000, 10000, "");
        c.cfg.save();
        return c;
    }

    public void save() {
        if (cfg == null) return;
        cfg.get("mods", "fps", true).set(fps);
        cfg.get("mods", "cps", true).set(cps);
        cfg.get("mods", "keystrokes", true).set(keystrokes);
        cfg.get("mods", "tntTimer", true).set(tntTimer);
        cfg.get("mods", "hitbox", true).set(hitbox);
        cfg.get("mods", "reach", true).set(reach);
        cfg.get("mods", "coords", true).set(coords);
        cfg.get("mods", "masterShowHud", true).set(masterShowHud);
        cfg.get("hud", "fpsX", 2).set(fpsX);
        cfg.get("hud", "fpsY", 2).set(fpsY);
        cfg.get("hud", "cpsX", 2).set(cpsX);
        cfg.get("hud", "cpsY", 12).set(cpsY);
        cfg.get("hud", "keysX", 2).set(keysX);
        cfg.get("hud", "keysY", 22).set(keysY);
        cfg.get("hud", "tntX", 90).set(tntX);
        cfg.get("hud", "tntY", 2).set(tntY);
        cfg.get("hud", "reachX", 2).set(reachX);
        cfg.get("hud", "reachY", 60).set(reachY);
        cfg.get("hud", "coordsX", 2).set(coordsX);
        cfg.get("hud", "coordsY", 70).set(coordsY);
        cfg.save();
    }
}
