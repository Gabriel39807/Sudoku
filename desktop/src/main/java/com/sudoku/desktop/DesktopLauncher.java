package com.sudoku.desktop;

import com.badlogic.gdx.backends.lwjgl3.Lwjgl3Application;
import com.badlogic.gdx.backends.lwjgl3.Lwjgl3ApplicationConfiguration;
import com.sudoku.core.SudokuGame;

public final class DesktopLauncher {
    private DesktopLauncher() {
    }

    public static void main(String[] args) {
        Lwjgl3ApplicationConfiguration config = new Lwjgl3ApplicationConfiguration();
        config.setTitle("Sudoku");
        config.setWindowedMode(540, 960);
        config.useVsync(true);
        config.setForegroundFPS(60);

        new Lwjgl3Application(new SudokuGame(), config);
    }
}
