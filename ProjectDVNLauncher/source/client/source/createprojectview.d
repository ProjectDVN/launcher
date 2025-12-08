module createprojectview;

import dvn;
import globals;

import std.conv : to;
import std.file : read, dirEntries, SpanMode, getcwd, rename, exists, mkdir, rmdir, write, mkdirRecurse, isDir;
import std.path : baseName, dirName;
import std.process : spawnProcess, Config, browse, executeShell, execute;
import std.array : replace, split;
import std.algorithm : endsWith;
import std.zip;
import std.string : strip;

GameSettings loadGameSettingsJson(string projectPath)
{
    auto settingsJsonPath = projectPath ~ "/build/client/data/settings.json";

    import std.file : readText;

    string text = readText(settingsJsonPath);
    string[] errorMessages;
    GameSettings gameSettings;
    if (!deserializeJsonSafe!GameSettings(text, gameSettings, errorMessages))
    {
        throw new Exception(errorMessages[0]);
    }

    return gameSettings;
}

void saveGameSettingsJson(string projectPath, GameSettings settings)
{
    auto settingsJsonPath = projectPath ~ "/build/client/data/settings.json";

    import std.file : write;
  
    string serializedJson;
    if (!serializeJsonSafe(settings, serializedJson, true))
    {
        return;
    }

    write(settingsJsonPath, serializedJson);
}

public final class ProjectColorTheme
{
    public:
    final:
    string textColor;
    string backgroundColor1;
    string backgroundColor2;
    string borderColor;
}

ProjectColorTheme getTheme(string name)
{
    switch (name)
    {
        case "green":
            auto green = new ProjectColorTheme;
            green.textColor = "fff";
            green.backgroundColor1 = "7dcea0";
            green.backgroundColor2 = "52be80";
            green.borderColor = "27ae60";
            return green;

        case "red":
            auto red = new ProjectColorTheme;
            red.textColor = "fff";
            red.backgroundColor1 = "f1948a";
            red.backgroundColor2 = "ec7063";
            red.borderColor = "e74c3c";
            return red;

        case "yellow":
            auto yellow = new ProjectColorTheme;
            yellow.textColor = "fff";
            yellow.backgroundColor1 = "f7dc6f";
            yellow.backgroundColor2 = "f4d03f";
            yellow.borderColor = "f1c40f";
            return yellow;

        case "pink":
            auto pink = new ProjectColorTheme;
            pink.textColor = "fff";
            pink.backgroundColor1 = "f06292";
            pink.backgroundColor2 = "ec407a";
            pink.borderColor = "e91e63";
            return pink;

        case "purple":
            auto purple = new ProjectColorTheme;
            purple.textColor = "fff";
            purple.backgroundColor1 = "bb8fce";
            purple.backgroundColor2 = "a569bd";
            purple.borderColor = "8e44ad";
            return purple;

        case "orange":
            auto orange = new ProjectColorTheme;
            orange.textColor = "fff";
            orange.backgroundColor1 = "f8c471";
            orange.backgroundColor2 = "f5b041";
            orange.borderColor = "f39c12";
            return orange;

        case "darkred":
            auto darkred = new ProjectColorTheme;
            darkred.textColor = "fff";
            darkred.backgroundColor1 = "c0392b";
            darkred.backgroundColor2 = "a93226";
            darkred.borderColor = "922b21";
            return darkred;

        case "blue":
        default:
            auto blue = new ProjectColorTheme;
            blue.textColor = "fff";
            blue.backgroundColor1 = "85c1e9";
            blue.backgroundColor2 = "5dade2";
            blue.borderColor = "3498db";
            return blue;
    }
}

public final class CreateProjectView : View
{
    public:
    final:
    this(Window window)
    {
        super(window);
    }

    void renderLinkLine(Window window, string textColor, GameSettings settings)
    {
        auto documentationLabel = new Label(window);
        addComponent(documentationLabel);
        documentationLabel.fontName = settings.defaultFont;
        documentationLabel.fontSize = 22;
        documentationLabel.color = textColor.getColorByHex;
        documentationLabel.text = "DOCUMENTATION";
        documentationLabel.shadow = true;
        documentationLabel.isLink = true;
        documentationLabel.position = IntVector(14, window.height - (documentationLabel.height + 14));
        documentationLabel.updateRect();
        documentationLabel.show();

        documentationLabel.onMouseButtonUp(new MouseButtonEventHandler((b,p) {
            browse("https://projectdvn.com/docs/index");
        }));
        
        auto websiteLabel = new Label(window);
        addComponent(websiteLabel);
        websiteLabel.fontName = settings.defaultFont;
        websiteLabel.fontSize = 22;
        websiteLabel.color = textColor.getColorByHex;
        websiteLabel.text = "WEBSITE";
        websiteLabel.shadow = true;
        websiteLabel.isLink = true;
        websiteLabel.position = IntVector(documentationLabel.x + documentationLabel.width + 14, window.height - (websiteLabel.height + 14));
        websiteLabel.updateRect();
        websiteLabel.show();

        websiteLabel.onMouseButtonUp(new MouseButtonEventHandler((b,p) {
            browse("https://projectdvn.com/");
        }));
    }

    private
    {
        ProjectColorTheme selectedColorTheme;
        Panel selectedPanel;
    }

    protected override void onInitialize(bool useCache)
    {
        EXT_EnableKeyboardState();

        auto window = super.window;

        auto settings = getGlobalSettings();

        auto bgImage = new Image(window, "MainMenuBackground");
        addComponent(bgImage);
        bgImage.position = IntVector(
            (window.width / 2) - (bgImage.width / 2),
            (window.height / 2) - (bgImage.height / 2));
        bgImage.show();

        auto textColor = "fff";
        auto selectColor = "85c1e9";
        auto buttonTextColor = "fff";
        auto buttonBackgroundColor = "85c1e9";
        auto buttonBackgroundBottomColor = "5dade2";
        auto buttonBorderColor = "3498db";
        auto textBoxColor = "85c1e9";
        auto textBoxBorderColor = "3498db";

        renderLinkLine(window, textColor, settings);

        auto cancelLabel = new Label(window);
        addComponent(cancelLabel);
        cancelLabel.fontName = settings.defaultFont;
        cancelLabel.fontSize = 22;
        cancelLabel.color = textColor.getColorByHex;
        cancelLabel.text = "CANCEL";
        cancelLabel.shadow = true;
        cancelLabel.isLink = true;
        cancelLabel.position = IntVector(14, window.height - (cancelLabel.height + 55));
        cancelLabel.updateRect();
        cancelLabel.show();

        cancelLabel.onMouseButtonUp(new MouseButtonEventHandler((b,p) {
            displayView("Overview");
        }));

        auto saveLabel = new Label(window);
        addComponent(saveLabel);
        saveLabel.fontName = settings.defaultFont;
        saveLabel.fontSize = 22;
        saveLabel.color = textColor.getColorByHex;
        saveLabel.text = "SAVE";
        saveLabel.shadow = true;
        saveLabel.isLink = true;
        saveLabel.position = IntVector(window.width - (saveLabel.width + 14), window.height - (saveLabel.height + 55));
        saveLabel.updateRect();
        saveLabel.show();

        auto projectIDTextBox = new TextBox(window);
        auto projectNameTextBox = new TextBox(window);

        auto shouldUpdate =
            currentProjectName && currentProjectName.strip.length &&
            currentProjectTitle && currentProjectTitle.strip.length;

        saveLabel.onMouseButtonUp(new MouseButtonEventHandler((b,p) {
            if (!projectIDTextBox.text || !projectIDTextBox.text.strip.length)
            {
                return;
            }
            if (!projectNameTextBox.text || !projectNameTextBox.text.strip.length)
            {
                return;
            }
            auto realProjectName = projectIDTextBox.text.strip.to!string;
            auto realProjectTitle = projectNameTextBox.text.strip.to!string;
            auto projectName = realProjectName.replace(" ", "_");
            auto projectFolder = "projects/" ~ projectName;

            if (shouldUpdate)
            {
                rename("projects/" ~ currentProjectName.replace(" ", "_"), projectFolder);

                auto gameSettings = loadGameSettingsJson(projectFolder);

                gameSettings.title = realProjectTitle;
                gameSettings.loadTitle = "LOADING " ~ realProjectTitle;

                saveGameSettingsJson(projectFolder, gameSettings);
            }
            else if (!exists(projectFolder))
            {
                mkdir(projectFolder);

                try
                {
                    auto zip = new ZipArchive(read("copyproject/copy.zip"));

                    foreach (name, am; zip.directory)
                    {
                        zip.expand(am);

                        if (am.expandedData.length != am.expandedSize)
                        {
                            throw new Exception("Invalid zip data.");
                        }

                        auto dir = projectFolder ~ "/" ~ dirName(name).replace("\\", "/");

                        if (!exists(dir))
                        {
                            mkdirRecurse(dir);
                        }

                        bool isDirName(string path)
                        {
                            if (path.endsWith("/"))
                            {
                                return true;
                            }

                            auto base = baseName(path);
                            auto descriptor = base.split(".");
                            if (descriptor.length == 2 &&
                            descriptor[0].strip.length)
                            {
                                return false;
                            }

                            return true;
                        }

                        if (!isDirName(name))
                        {
                            write(projectFolder ~ "/" ~ name, am.expandedData);
                        }
                    }

                    auto gameSettings = loadGameSettingsJson(projectFolder);

                    gameSettings.title = realProjectTitle;
                    gameSettings.loadTitle = "LOADING " ~ realProjectTitle;

                    string textColor = "fff";
                    string backgroundColor1 = "85c1e9";
                    string backgroundColor2 = "5dade2";
                    string borderColor = "3498db";

                    if (selectedColorTheme)
                    {
                        textColor = selectedColorTheme.textColor;
                        backgroundColor1 = selectedColorTheme.backgroundColor1;
                        backgroundColor2 = selectedColorTheme.backgroundColor2;
                        borderColor = selectedColorTheme.borderColor;
                    }

                    gameSettings.dialoguePanelBackgroundColor = backgroundColor2;
                    gameSettings.dialoguePanelBorderColor = borderColor;

                    gameSettings.namePanelBackgroundColor = backgroundColor2;
                    gameSettings.namePanelBorderColor = borderColor;

                    gameSettings.buttonTextColor = textColor;
                    gameSettings.buttonBackgroundColor = backgroundColor1;
                    gameSettings.buttonBackgroundBottomColor = backgroundColor2;
                    gameSettings.buttonBorderColor = borderColor;

                    gameSettings.dropdownTextColor = textColor;
                    gameSettings.dropDownBackgroundColor = backgroundColor1;
                    gameSettings.dropDownBorderColor = borderColor;

                    gameSettings.checkBoxBackgroundColor = backgroundColor1 == "85c1e9" ? backgroundColor2 : backgroundColor1;
                    gameSettings.checkBoxBorderColor = borderColor;

                    gameSettings.textBoxColor = backgroundColor1;
                    gameSettings.textBoxTextColor = textColor;
                    gameSettings.textBoxBorderColor = borderColor;

                    saveGameSettingsJson(projectFolder, gameSettings);
                }
                catch (Throwable t)
                {
                    rmdir(projectFolder);

                    throw t;
                }
            }

            displayView("Overview");
        }));

        auto projectIDLabel = new Label(window);
        addComponent(projectIDLabel);
        projectIDLabel.fontName = settings.defaultFont;
        projectIDLabel.fontSize = 48;
        projectIDLabel.color = textColor.getColorByHex;
        projectIDLabel.text = "PROJECT ID (short-name)";
        projectIDLabel.shadow = true;
        projectIDLabel.position = IntVector(
            (window.width / 2) - (projectIDLabel.width / 2),
            120);
        projectIDLabel.updateRect();
        projectIDLabel.show();

        addComponent(projectIDTextBox);
        projectIDTextBox.fontName = settings.defaultFont;
        projectIDTextBox.fontSize = 24;
        projectIDTextBox.size = IntVector((window.width / 100) * 50, 42);
        projectIDTextBox.moveBelow(projectIDLabel, 14, true);
        projectIDTextBox.textColor = textColor.getColorByHex;
        projectIDTextBox.maxCharacters = 24;
        projectIDTextBox.textPadding = 8;
        projectIDTextBox.text = shouldUpdate ? currentProjectName.to!dstring : "";
        
        projectIDTextBox.defaultPaint.backgroundColor = textBoxColor.getColorByHex;
        projectIDTextBox.hoverPaint.backgroundColor = textBoxColor.getColorByHex.changeAlpha(220);
        projectIDTextBox.focusPaint.backgroundColor = textBoxColor.getColorByHex.changeAlpha(150);
        projectIDTextBox.defaultPaint.borderColor = textBoxBorderColor.getColorByHex;
        projectIDTextBox.hoverPaint.borderColor = textBoxBorderColor.getColorByHex;
        projectIDTextBox.focusPaint.borderColor = textBoxBorderColor.getColorByHex;
        projectIDTextBox.defaultPaint.shadowColor = textBoxColor.getColorByHex;
        projectIDTextBox.hoverPaint.shadowColor = textBoxColor.getColorByHex.changeAlpha(220);
        projectIDTextBox.focusPaint.shadowColor = textBoxColor.getColorByHex.changeAlpha(150);

        projectIDTextBox.restyle();
        projectIDTextBox.show();
        if (shouldUpdate)
        {
            projectIDTextBox.defaultPaint.backgroundColor = "444".getColorByHex;
            projectIDTextBox.hoverPaint.backgroundColor = "444".getColorByHex.changeAlpha(220);
            projectIDTextBox.focusPaint.backgroundColor = "444".getColorByHex.changeAlpha(150);
            projectIDTextBox.disable();
            projectIDTextBox.restyle();
            projectIDTextBox.show();
        }
        
        auto projectIDDescriptionLabel = new Label(window);
        addComponent(projectIDDescriptionLabel);
        projectIDDescriptionLabel.fontName = settings.defaultFont;
        projectIDDescriptionLabel.fontSize = 18;
        projectIDDescriptionLabel.color = textColor.getColorByHex;
        projectIDDescriptionLabel.text = shouldUpdate ? "The Project ID" : "Enter the ID of the project (a-z,0-9).";
        projectIDDescriptionLabel.shadow = true;
        projectIDDescriptionLabel.moveBelow(projectIDTextBox, 14, true);
        projectIDDescriptionLabel.updateRect();
        projectIDDescriptionLabel.show();
        
        auto projectIDLine = new Panel(window);
        addComponent(projectIDLine);
        projectIDLine.size = IntVector(projectIDTextBox.width, 4);
        projectIDLine.moveBelow(projectIDDescriptionLabel, 14, true);
        projectIDLine.fillColor = selectColor.getColorByHex;
        projectIDLine.show();
        
        auto projectNameLabel = new Label(window);
        addComponent(projectNameLabel);
        projectNameLabel.fontName = settings.defaultFont;
        projectNameLabel.fontSize = 48;
        projectNameLabel.color = textColor.getColorByHex;
        projectNameLabel.text = "PROJECT NAME";
        projectNameLabel.shadow = true;
        projectNameLabel.moveBelow(projectIDLine, 14, true);
        projectNameLabel.updateRect();
        projectNameLabel.show();

        addComponent(projectNameTextBox);
        projectNameTextBox.fontName = settings.defaultFont;
        projectNameTextBox.fontSize = 24;
        projectNameTextBox.size = IntVector((window.width / 100) * 50, 42);
        projectNameTextBox.moveBelow(projectNameLabel, 14, true);
        projectNameTextBox.textColor = textColor.getColorByHex;
        projectNameTextBox.maxCharacters = 80;
        projectNameTextBox.textPadding = 8;
        projectNameTextBox.text = shouldUpdate ? currentProjectTitle.to!dstring : "";
        
        projectNameTextBox.defaultPaint.backgroundColor = textBoxColor.getColorByHex;
        projectNameTextBox.hoverPaint.backgroundColor = textBoxColor.getColorByHex.changeAlpha(220);
        projectNameTextBox.focusPaint.backgroundColor = textBoxColor.getColorByHex.changeAlpha(150);
        projectNameTextBox.defaultPaint.borderColor = textBoxBorderColor.getColorByHex;
        projectNameTextBox.hoverPaint.borderColor = textBoxBorderColor.getColorByHex;
        projectNameTextBox.focusPaint.borderColor = textBoxBorderColor.getColorByHex;
        projectNameTextBox.defaultPaint.shadowColor = textBoxColor.getColorByHex;
        projectNameTextBox.hoverPaint.shadowColor = textBoxColor.getColorByHex.changeAlpha(220);
        projectNameTextBox.focusPaint.shadowColor = textBoxColor.getColorByHex.changeAlpha(150);

        projectNameTextBox.restyle();
        projectNameTextBox.show();
        
        auto projectDescriptionLabel = new Label(window);
        addComponent(projectDescriptionLabel);
        projectDescriptionLabel.fontName = settings.defaultFont;
        projectDescriptionLabel.fontSize = 18;
        projectDescriptionLabel.color = textColor.getColorByHex;
        projectDescriptionLabel.text = "Enter the name of the project.";
        projectDescriptionLabel.shadow = true;
        projectDescriptionLabel.moveBelow(projectNameTextBox, 14, true);
        projectDescriptionLabel.updateRect();
        projectDescriptionLabel.show();
        
        auto projectNameLine = new Panel(window);
        addComponent(projectNameLine);
        projectNameLine.size = IntVector(projectNameTextBox.width, 4);
        projectNameLine.moveBelow(projectDescriptionLabel, 14, true);
        projectNameLine.fillColor = selectColor.getColorByHex;
        projectNameLine.show();

        if (!shouldUpdate)
        {
            auto projectThemeDescriptionLabel = new Label(window);
            addComponent(projectThemeDescriptionLabel);
            projectThemeDescriptionLabel.fontName = settings.defaultFont;
            projectThemeDescriptionLabel.fontSize = 18;
            projectThemeDescriptionLabel.color = textColor.getColorByHex;
            projectThemeDescriptionLabel.text = "Select the color theme for the project";
            projectThemeDescriptionLabel.shadow = true;
            projectThemeDescriptionLabel.moveBelow(projectNameLine, 14, true);
            projectThemeDescriptionLabel.updateRect();
            projectThemeDescriptionLabel.show();
            
            int originalColorX = projectNameTextBox.x + 136;
            int colorX = originalColorX;
            int colorY = projectThemeDescriptionLabel.y + projectThemeDescriptionLabel.height + 14;
            Panel lastColorPanel;
            void createColorPanel(string color, bool selected)
            {
                auto colorTheme = getTheme(color);

                auto colorPanel = new Panel(window);
                addComponent(colorPanel);
                colorPanel.size = IntVector(78, 32);
                colorPanel.position = IntVector(colorX, colorY);
                colorPanel.fillColor = colorTheme.backgroundColor1.getColorByHex;
                if (selected)
                {
                    colorPanel.borderColor = "000".getColorByHex;
                    selectedColorTheme = colorTheme;
                    selectedPanel = colorPanel;
                }
                colorPanel.show();

                colorPanel.onMouseButtonUp(new MouseButtonEventHandler((b,p) {
                    if (selectedPanel)
                    {
                        selectedPanel.borderColor = getColorByName("transparent");
                    }
                    selectedColorTheme = colorTheme;
                    selectedPanel = colorPanel;
                    selectedPanel.borderColor = "000".getColorByHex;
                }));

                lastColorPanel = colorPanel;
                colorX += lastColorPanel.width + 8;
            }

            createColorPanel("blue", true);
            createColorPanel("red", false);
            createColorPanel("green", false);
            createColorPanel("yellow", false);
            
            colorY += lastColorPanel.height + 14;
            colorX = originalColorX;

            createColorPanel("pink", false);
            createColorPanel("purple", false);
            createColorPanel("orange", false);
            createColorPanel("darkred", false);
        }
    }
}