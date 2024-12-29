module overviewview;

import dvn;

import globals;

import std.conv : to;
import std.file : dirEntries, SpanMode, getcwd;
import std.path : baseName;
import std.process : spawnProcess, Config, browse, executeShell, execute;
import std.array : replace;

public final class DubJson
{
    public:
    final:
    string targetName;
}

private DubJson loadDub(string projectPath)
{
    auto dubJsonPath = projectPath ~ "/source/client/dub.json";

    import std.file : readText;

    string text = readText(dubJsonPath);
    string[] errorMessages;
    DubJson dubJson;
    if (!deserializeJsonSafe!DubJson(text, dubJson, errorMessages))
    {
        throw new Exception(errorMessages[0]);
    }

    return dubJson;
}

public final class OverviewView : View
{
    public:
    final:
    this(Window window)
    {
        super(window);
    }

    private
    {
        Label projectNameLabel;
        Panel projectNameLabelLine;
        Button launchProjectButton;
        Label openFolderLabel;
        Panel openFolderLabelLine;
        Label[] openFolderLabels;
        Label editProjectLabel;
        Panel editProjectLabelLine;
        Label editProjectNameLabel;
        Label[] editProjectLabels;

        string _currentProjectName;
        string _currentProjectPath;
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
            browse("https://dvn-docs.readthedocs.io/en/latest/");
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
            browse("https://github.com/ProjectDVN/dvn");
        }));

        auto exitLabel = new Label(window);
        addComponent(exitLabel);
        exitLabel.fontName = settings.defaultFont;
        exitLabel.fontSize = 22;
        exitLabel.color = textColor.getColorByHex;
        exitLabel.text = "EXIT";
        exitLabel.shadow = true;
        exitLabel.isLink = true;
        exitLabel.position = IntVector(window.width - (exitLabel.width + 14), window.height - (exitLabel.height + 14));
        exitLabel.updateRect();
        exitLabel.show();

        exitLabel.onMouseButtonUp(new MouseButtonEventHandler((b,p) {
            getApplication().stop();
        }));
    }

    protected override void onInitialize(bool useCache)
    {
        EXT_DisableKeyboardState();

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

        renderLinkLine(window, textColor, settings);
        
        void restyleButton(Button button)
        {
            button.textColor = buttonTextColor.getColorByHex;

            button.defaultPaint.backgroundColor = buttonBackgroundColor.getColorByHex;
            button.defaultPaint.backgroundBottomColor = buttonBackgroundBottomColor.getColorByHex;
            button.defaultPaint.borderColor = buttonBorderColor.getColorByHex;
            button.defaultPaint.shadowColor = buttonBackgroundColor.getColorByHex;

            button.hoverPaint.backgroundColor = button.defaultPaint.backgroundColor.changeAlpha(220);
            button.hoverPaint.backgroundBottomColor = button.defaultPaint.backgroundBottomColor.changeAlpha(220);
            button.hoverPaint.borderColor = button.defaultPaint.borderColor.changeAlpha(220);
            button.hoverPaint.shadowColor = buttonBackgroundColor.getColorByHex.changeAlpha(220);

            button.clickPaint.backgroundColor = button.defaultPaint.backgroundColor.changeAlpha(240);
            button.clickPaint.backgroundBottomColor = button.defaultPaint.backgroundBottomColor.changeAlpha(240);
            button.clickPaint.borderColor = button.defaultPaint.borderColor.changeAlpha(240);
            button.clickPaint.shadowColor = buttonBackgroundColor.getColorByHex.changeAlpha(240);

            button.restyle();

            button.show();
        }

        auto projectsLabel = new Label(window);
        addComponent(projectsLabel);
        projectsLabel.fontName = settings.defaultFont;
        projectsLabel.fontSize = 48;
        projectsLabel.color = textColor.getColorByHex;
        projectsLabel.text = "PROJECTS:";
        projectsLabel.shadow = true;
        projectsLabel.position = IntVector(14, 14);
        projectsLabel.updateRect();
        projectsLabel.show();

        auto projectsLine = new Panel(window);
        addComponent(projectsLine);
        projectsLine.size = IntVector(304 + 16, 4);
        projectsLine.position = IntVector(14, projectsLabel.y + projectsLabel.height + 8);
        projectsLine.fillColor = selectColor.getColorByHex;
        projectsLine.show();

        auto projectsPanel = new Panel(window);
        projectsPanel.fillColor = getColorByRGB(0,0,0,150);
        projectsPanel.size = IntVector(projectsLine.width - 16, 380);
        projectsPanel.position = IntVector(projectsLine.x, projectsLine.y + projectsLine.height + 8);
        addComponent(projectsPanel);

        auto scrollbarMessages = new ScrollBar(window, projectsPanel);
        addComponent(scrollbarMessages);
        scrollbarMessages.isVertical = true;
        scrollbarMessages.fillColor = getColorByRGB(0,0,0,150);
        scrollbarMessages.borderColor = getColorByRGB(0,0,0,150);
        projectsPanel.scrollMargin = IntVector(0,cast(int)((cast(double)projectsPanel.height / 3.5) / 2));
        scrollbarMessages.position = IntVector(projectsPanel.x + projectsPanel.width, projectsPanel.y);
        scrollbarMessages.buttonScrollAmount = cast(int)((cast(double)projectsPanel.height / 3.5) / 2);
        scrollbarMessages.fontName = settings.defaultFont;
        scrollbarMessages.fontSize = 8;
        scrollbarMessages.buttonTextColor = textColor.getColorByHex;
        scrollbarMessages.createDecrementButton("▲", "◀");
        scrollbarMessages.createIncrementButton("▼", "▶");
        scrollbarMessages.size = IntVector(16, projectsPanel.height);

        scrollbarMessages.updateScrollView();

        int projectLabelY = 14;
        Label lastSelectedProjectLabel;
        foreach (string name; dirEntries("projects", SpanMode.shallow))
        {
            auto closure = (Label pLabel, string pName, string pPath) { return () {
                pLabel.onMouseButtonUp(new MouseButtonEventHandler((b,p) {
                    if (lastSelectedProjectLabel)
                    {
                        lastSelectedProjectLabel.fillColor = getColorByName("transparent");
                    }

                    pLabel.fillColor = selectColor.getColorByHex;

                    lastSelectedProjectLabel = pLabel;

                    showProject(pPath, pName);
                }));
            };};

            auto projectLabel = new Label(window);
            projectsPanel.addComponent(projectLabel);
            projectLabel.fontName = settings.defaultFont;
            projectLabel.fontSize = 22;
            projectLabel.color = textColor.getColorByHex;
            projectLabel.text = baseName(name).replace("_", " ").to!dstring;
            projectLabel.shadow = true;
            projectLabel.isLink = true;
            projectLabel.position = IntVector(14, projectLabelY);
            projectLabel.updateRect();
            projectLabel.show();

            closure(projectLabel, baseName(name), name.replace("\\", "/"))();

            projectLabelY = projectLabel.y + projectLabel.height + 14;
        }
        
        scrollbarMessages.updateScrollView();
        
        auto createNewProjectLabel = new Label(window);
        addComponent(createNewProjectLabel);
        createNewProjectLabel.fontName = settings.defaultFont;
        createNewProjectLabel.fontSize = 22;
        createNewProjectLabel.color = "fff".getColorByHex;
        createNewProjectLabel.text = "CREATE NEW PROJECT";
        createNewProjectLabel.shadow = true;
        createNewProjectLabel.isLink = true;
        createNewProjectLabel.position = IntVector(14, projectsPanel.y + projectsPanel.height + 14);
        createNewProjectLabel.updateRect();
        createNewProjectLabel.show();

        createNewProjectLabel.onMouseButtonUp(new MouseButtonEventHandler((b,p) {
            currentProjectName = "";
            
            displayView("CreateProject");
        }));
        
        projectNameLabel = new Label(window);
        addComponent(projectNameLabel);
        projectNameLabel.fontName = settings.defaultFont;
        projectNameLabel.fontSize = 48;
        projectNameLabel.color = textColor.getColorByHex;
        projectNameLabel.text = "X";
        projectNameLabel.shadow = true;
        projectNameLabel.position = IntVector(projectsLine.x + projectsLine.width + 14, 14);
        projectNameLabel.updateRect();
        projectNameLabel.hide();

        projectNameLabelLine = new Panel(window);
        addComponent(projectNameLabelLine);
        projectNameLabelLine.size = IntVector(304, 4);
        projectNameLabelLine.position = IntVector(projectNameLabel.x, projectNameLabel.y + projectNameLabel.height + 8);
        projectNameLabelLine.fillColor = selectColor.getColorByHex;
        projectNameLabelLine.hide();
        
        launchProjectButton = new Button(window);
		addComponent(launchProjectButton);
		launchProjectButton.size = IntVector(projectNameLabelLine.width, 48);
		launchProjectButton.position = IntVector(projectNameLabelLine.x, projectNameLabelLine.y + projectNameLabelLine.height + 8);
		launchProjectButton.fontName = settings.defaultFont;
		launchProjectButton.fontSize = 22;
		launchProjectButton.textColor = "000".getColorByHex;
		launchProjectButton.text = "LAUNCH PROJECT";
		launchProjectButton.fitToSize = false;
		launchProjectButton.restyle();
        restyleButton(launchProjectButton);
		launchProjectButton.hide();
        launchProjectButton.onButtonClick(new MouseButtonEventHandler((b,p) {
            auto dubJson = loadDub(_currentProjectPath);

            auto workingPath = _currentProjectPath ~ "/build/client";
            auto processPath = workingPath ~ "/" ~ dubJson.targetName ~ ".exe";

            spawnProcess(processPath, ["foo" : "bar"], Config.detached, workingPath);
        }));
        
        openFolderLabel = new Label(window);
        addComponent(openFolderLabel);
        openFolderLabel.fontName = settings.defaultFont;
        openFolderLabel.fontSize = 48;
        openFolderLabel.color = textColor.getColorByHex;
        openFolderLabel.text = "OPEN FOLDER";
        openFolderLabel.shadow = true;
        openFolderLabel.position = IntVector(launchProjectButton.x, launchProjectButton.y + launchProjectButton.height + 14);
        openFolderLabel.updateRect();
        openFolderLabel.hide();

        openFolderLabelLine = new Panel(window);
        addComponent(openFolderLabelLine);
        openFolderLabelLine.size = IntVector(304, 4);
        openFolderLabelLine.position = IntVector(openFolderLabel.x, openFolderLabel.y + openFolderLabel.height + 8);
        openFolderLabelLine.fillColor = selectColor.getColorByHex;
        openFolderLabelLine.hide();

        int openFolderLabelY = openFolderLabelLine.y + openFolderLabelLine.height + 8;

        void createOpenFolderLabel(string text, string folderToOpen)
        {
            auto openFolderLabelEntry = new Label(window);
            addComponent(openFolderLabelEntry);
            openFolderLabelEntry.fontName = settings.defaultFont;
            openFolderLabelEntry.fontSize = 22;
            openFolderLabelEntry.color = textColor.getColorByHex;
            openFolderLabelEntry.text = text.to!dstring;
            openFolderLabelEntry.shadow = true;
            openFolderLabelEntry.isLink = true;
            openFolderLabelEntry.position = IntVector(openFolderLabelLine.x, openFolderLabelY);
            openFolderLabelEntry.updateRect();
            openFolderLabelEntry.hide();

            openFolderLabelEntry.onMouseButtonUp(new MouseButtonEventHandler((b,p) {
                auto path = _currentProjectPath ~ "/build/client/data" ~ folderToOpen;

                spawnProcess(["cmd.exe", "/c start " ~  path], ["foo": "bar"], Config.detached, path);
            }));

            openFolderLabels ~= openFolderLabelEntry;

            openFolderLabelY = openFolderLabelEntry.y + openFolderLabelEntry.height + 14;
        }

        createOpenFolderLabel("PROJECT FOLDER", "");
        createOpenFolderLabel("MAIN BACKGROUNDS", "/backgrounds");
        createOpenFolderLabel("FONTS", "/fonts");
        createOpenFolderLabel("GAME FOLDER", "/game");
        createOpenFolderLabel("BACKGROUNDS", "/game/backgrounds");
        createOpenFolderLabel("CHARACTERS", "/game/characters");
        createOpenFolderLabel("IMAGES", "/game/images");
        createOpenFolderLabel("SCRIPTS", "/game/scripts");
        createOpenFolderLabel("VIEWS", "/game/views");
        
        editProjectLabel = new Label(window);
        addComponent(editProjectLabel);
        editProjectLabel.fontName = settings.defaultFont;
        editProjectLabel.fontSize = 48;
        editProjectLabel.color = textColor.getColorByHex;
        editProjectLabel.text = "EDIT PROJECT";
        editProjectLabel.shadow = true;
        editProjectLabel.position = IntVector(openFolderLabelLine.x + openFolderLabelLine.width + 14, openFolderLabel.y);
        editProjectLabel.updateRect();
        editProjectLabel.hide();

        editProjectLabelLine = new Panel(window);
        addComponent(editProjectLabelLine);
        editProjectLabelLine.size = IntVector(304, 4);
        editProjectLabelLine.position = IntVector(editProjectLabel.x, editProjectLabel.y + editProjectLabel.height + 8);
        editProjectLabelLine.fillColor = selectColor.getColorByHex;
        editProjectLabelLine.hide();

        int editProjectLabelY = editProjectLabelLine.y + editProjectLabelLine.height + 8;

        void createEditProjectLabel(string text, void delegate() action)
        {
            auto editProjectLabelEntry = new Label(window);
            addComponent(editProjectLabelEntry);
            editProjectLabelEntry.fontName = settings.defaultFont;
            editProjectLabelEntry.fontSize = 22;
            editProjectLabelEntry.color = textColor.getColorByHex;
            editProjectLabelEntry.text = text.to!dstring;
            editProjectLabelEntry.shadow = true;
            editProjectLabelEntry.isLink = true;
            editProjectLabelEntry.position = IntVector(editProjectLabelLine.x, editProjectLabelY);
            editProjectLabelEntry.updateRect();
            editProjectLabelEntry.hide();

            editProjectLabelEntry.onMouseButtonUp(new MouseButtonEventHandler((b,p) {
                if (action)
                {
                    action();
                }
            }));

            editProjectLabels ~= editProjectLabelEntry;

            editProjectLabelY = editProjectLabelEntry.y + editProjectLabelEntry.height + 14;
        }

        createEditProjectLabel("PROJECT NAME",
        {
            currentProjectName = _currentProjectName.replace("_", " ");
            
            displayView("CreateProject");
        });

        createEditProjectLabel("CLEAR SAVE FILES",
        {
            import createprojectview;

            auto gameSettings = loadGameSettingsJson(_currentProjectPath);

            gameSettings.saves = null;

            saveGameSettingsJson(_currentProjectPath, gameSettings);
        });

        createEditProjectLabel("CLEAR HISTORY",
        {
            import std.file : exists, remove;

            if (!exists(_currentProjectPath ~ "/build/client/data/game/history.json"))
            {
                return;
            }

            remove(_currentProjectPath ~ "/build/client/data/game/history.json");
        });
    }

    void showProject(string path, string name)
    {
        _currentProjectName = name;
        _currentProjectPath = getcwd.replace("\\", "/") ~ "/" ~ path;
        
        projectNameLabel.text = ("PROJECT: " ~ _currentProjectName.replace("_", " ")).to!dstring;
        projectNameLabel.show();
        projectNameLabelLine.show();

        launchProjectButton.show();

        openFolderLabel.show();
        openFolderLabelLine.show();

        foreach (openFolderLabel; openFolderLabels)
        {
            openFolderLabel.show();
        }

        editProjectLabel.show();
        editProjectLabelLine.show();

        foreach (editProjectLabel; editProjectLabels)
        {
            editProjectLabel.show();
        }
    }
}