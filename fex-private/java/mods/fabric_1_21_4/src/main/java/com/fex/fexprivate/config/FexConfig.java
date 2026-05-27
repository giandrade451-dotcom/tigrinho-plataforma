package com.fex.fexprivate.config;

import com.google.gson.Gson;
import com.google.gson.GsonBuilder;
import net.fabricmc.loader.api.FabricLoader;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;

public class FexConfig {
    private static final Gson GSON = new GsonBuilder().setPrettyPrinting().create();
    private static final Path PATH = FabricLoader.getInstance().getConfigDir().resolve("fexprivate.json");

    public boolean fps = true;
    public boolean cps = true;
    public boolean keystrokes = true;
    public boolean tntTimer = true;
    public boolean hitbox = false;
    public boolean reach = true;
    public boolean coords = true;
    public boolean masterShowHud = true;

    public Pos fpsPos = new Pos(2, 2);
    public Pos cpsPos = new Pos(2, 12);
    public Pos keysPos = new Pos(2, 22);
    public Pos tntPos = new Pos(90, 2);
    public Pos reachPos = new Pos(2, 42);
    public Pos coordsPos = new Pos(2, 52);

    public static class Pos {
        public int x;
        public int y;
        public Pos(int x, int y) { this.x = x; this.y = y; }
    }

    public static FexConfig load() {
        try {
            if (Files.exists(PATH)) {
                return GSON.fromJson(Files.readString(PATH), FexConfig.class);
            }
        } catch (IOException e) {
            // fall through to default
        }
        FexConfig c = new FexConfig();
        c.save();
        return c;
    }

    public void save() {
        try {
            Files.createDirectories(PATH.getParent());
            Files.writeString(PATH, GSON.toJson(this));
        } catch (IOException ignored) {}
    }
}
