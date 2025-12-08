module editcharactersview;

import dvn;
import globals;

import std.conv : to;
import std.algorithm : sort, filter;
import std.array : array, replace;
import std.process : browse;
import std.file : exists;
import std.string : startsWith;

public final class Character
{
    string name;
    TextBox nameValue;

    CharacterExpression[] expressions;

    string getExpressionPath()
    {
        string searchKey = "";

        foreach (expression; expressions)
        {
            if (expression.name == "default")
            {
                searchKey = expression.value;
                break;
            }
        }

        foreach (expression; expressions)
        {
            if (expression.name == searchKey)
            {
                return expression.value;
            }
        }

        return expressions && expressions.length ? expressions[0].value : null;
    }
}

public final class CharacterExpression
{
    string name;
    string value;

    TextBox nameValue;
    TextBox valueValue;

    int opCmp(ref const CharacterExpression other) const
    {
        if (!value || !value.length)
        {
            return 0;
        }
        
        return 1;
    }
}

private Character[] characters;

string[string][string] generateCharactersOutput()
{
    string[string][string] charactersOutput;

    if (characters && characters.length)
    {
        foreach (character; characters)
        {
            string[string] expressions;

            if (character.expressions && character.expressions.length)
            {
                foreach (expression; character.expressions)
                {
                    if (expression.nameValue && expression.nameValue.text &&
                        expression.nameValue.text.length &&
                        expression.valueValue)
                    {
                        expressions[expression.nameValue.text.to!string] = expression.valueValue.text.to!string;
                    }
                    else if (expression.name && expression.name.length)
                    {
                        expressions[expression.name] = expression.value;
                    }
                }
            }

            if (character.nameValue && character.nameValue.text &&
                character.nameValue.text.length)
            {
                charactersOutput[character.nameValue.text.to!string] = expressions;
            }
            else if (character.name && character.name.length)
            {
                charactersOutput[character.name] = expressions;
            }
        }
    }

    return charactersOutput;
}

void saveCharactersJson(string projectPath, string[string][string] charactersJson)
{
    auto charactersJsonPath = projectPath ~ "/build/client/data/game/characters.json";

    import std.file : write;
  
    string serializedJson;
    if (!serializeJsonSafe(charactersJson, serializedJson, true))
    {
        return;
    }

    write(charactersJsonPath, serializedJson);
}

void loadCharactersJson(string projectPath)
{
    characters = [];

    auto charactersJsonPath = projectPath ~ "/build/client/data/game/characters.json";

    import std.file : readText;

    string text = readText(charactersJsonPath);
    string[] errorMessages;
    string[string][string] charactersDeserialized;
    if (!deserializeJsonSafe!(string[string][string])(text, charactersDeserialized, errorMessages))
    {
        throw new Exception(errorMessages[0]);
    }

    if (!charactersDeserialized)
    {
        return;
    }
    
    foreach (character,expressions; charactersDeserialized)
    {
        auto c = new Character;
        c.name = character;

        if (expressions)
        {
            foreach (expression,value; expressions)
            {
                auto e = new CharacterExpression;
                e.name = expression;
                e.value = value;

                c.expressions ~= e;
            }
        }

        characters ~= c;
    }
}

public final class EditCharactersView : View
{
    public:
    final:
    this(Window window)
    {
        super(window);
    }

    private Panel charsLine;

    const textColor = "fff";
    const selectColor = "85c1e9";
    const buttonTextColor = "fff";
    const buttonBackgroundColor = "85c1e9";
    const buttonBackgroundBottomColor = "5dade2";
    const buttonBorderColor = "3498db";
    const textBoxColor = "85c1e9";
    const textBoxBorderColor = "3498db";

    private string _projectPath;

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

    protected override void onInitialize(bool useCache)
    {
        EXT_EnableKeyboardState();

        auto window = super.window;

        clean();
        
        auto settings = getGlobalSettings();
        _projectPath = "projects/" ~ currentProjectName;
        loadCharactersJson(_projectPath);
        
        auto bgImage = new Image(window, "MainMenuBackground");
        addComponent(bgImage);
        bgImage.position = IntVector(
            (window.width / 2) - (bgImage.width / 2),
            (window.height / 2) - (bgImage.height / 2));
        bgImage.show();

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

        auto charsLabel = new Label(window);
        addComponent(charsLabel);
        charsLabel.fontName = settings.defaultFont;
        charsLabel.fontSize = 48;
        charsLabel.color = textColor.getColorByHex;
        charsLabel.text = "CHARACTERS:";
        charsLabel.shadow = true;
        charsLabel.position = IntVector(14, 14);
        charsLabel.updateRect();
        charsLabel.show();

        charsLine = new Panel(window);
        addComponent(charsLine);
        charsLine.size = IntVector(304 + 16, 4);
        charsLine.position = IntVector(14, charsLabel.y + charsLabel.height + 8);
        charsLine.fillColor = selectColor.getColorByHex;
        charsLine.show();

        auto charsPanel = new Panel(window);
        charsPanel.fillColor = getColorByRGB(0,0,0,150);
        charsPanel.size = IntVector(charsLine.width - 16, 380);
        charsPanel.position = IntVector(charsLine.x, charsLine.y + charsLine.height + 8);
        addComponent(charsPanel);

        auto scrollbarMessages = new ScrollBar(window, charsPanel);
        addComponent(scrollbarMessages);
        scrollbarMessages.isVertical = true;
        scrollbarMessages.fillColor = getColorByRGB(0,0,0,150);
        scrollbarMessages.borderColor = getColorByRGB(0,0,0,150);
        charsPanel.scrollMargin = IntVector(0,cast(int)((cast(double)charsPanel.height / 3.5) / 2));
        scrollbarMessages.position = IntVector(charsPanel.x + charsPanel.width, charsPanel.y);
        scrollbarMessages.buttonScrollAmount = cast(int)((cast(double)charsPanel.height / 3.5) / 2);
        scrollbarMessages.fontName = settings.defaultFont;
        scrollbarMessages.fontSize = 8;
        scrollbarMessages.buttonTextColor = textColor.getColorByHex;
        scrollbarMessages.createDecrementButton("▲", "◀");
        scrollbarMessages.createIncrementButton("▼", "▶");
        scrollbarMessages.size = IntVector(16, charsPanel.height);

        scrollbarMessages.updateScrollView();

        Label lastCharacterLabel;
        Label lastSelectedCharLabel;

        foreach (character; characters)
        {
            auto closure = (Label pLabel, Character character) { return () {
                pLabel.onMouseButtonUp(new MouseButtonEventHandler((b,p) {
                    if (lastSelectedCharLabel)
                    {
                        lastSelectedCharLabel.fillColor = getColorByName("transparent");
                    }

                    pLabel.fillColor = selectColor.getColorByHex;

                    lastSelectedCharLabel = pLabel;

                    showExpressionView(character, settings);
                }));
            };};

            auto expressionPath = character.getExpressionPath;

            if (expressionPath.startsWith("data") || expressionPath.startsWith("/data") || expressionPath.startsWith("\\data"))
            {
                expressionPath = expressionPath.replace("\\", "/");

                if (expressionPath.startsWith("/"))
                {
                    expressionPath = expressionPath[1 .. $];
                }

                expressionPath = _projectPath ~ "/build/client/" ~ expressionPath;
            }

            Image characterImage;
            
            if (exists(expressionPath))
            {
                characterImage = new Image(window, expressionPath, true);
                charsPanel.addComponent(characterImage);
                characterImage.size = IntVector(22, 22);
                if (lastCharacterLabel)
                {
                    characterImage.moveBelow(lastCharacterLabel, 14);
                    characterImage.position = IntVector(14, characterImage.y);
                }
                else
                {
                    characterImage.position = IntVector(14, 14);
                }
                characterImage.show();
            }

            auto characterLabel = new Label(window);
            charsPanel.addComponent(characterLabel);
            characterLabel.fontName = settings.defaultFont;
            characterLabel.fontSize = 22;
            characterLabel.color = textColor.getColorByHex;
            characterLabel.text = character.name.to!dstring;
            characterLabel.shadow = true;
            characterLabel.isLink = true;
            if (characterImage)
            {
                characterLabel.moveRightOf(characterImage, 14);
            }
            else if (lastCharacterLabel)
            {
                characterLabel.moveBelow(lastCharacterLabel, 14);
                characterLabel.position = IntVector(14, characterLabel.y);
            }
            else
            {
                characterLabel.position = IntVector(14, 14);
            }
            lastCharacterLabel = characterLabel;
            characterLabel.updateRect();
            characterLabel.show();

            closure(characterLabel, character)();
        }
        
        scrollbarMessages.updateScrollView();
        charsPanel.makeScrollableWithWheel();
        
        auto createNewCharLabel = new Label(window);
        addComponent(createNewCharLabel);
        createNewCharLabel.fontName = settings.defaultFont;
        createNewCharLabel.fontSize = 22;
        createNewCharLabel.color = "fff".getColorByHex;
        createNewCharLabel.text = "CREATE NEW CHARACTER";
        createNewCharLabel.shadow = true;
        createNewCharLabel.isLink = true;
        createNewCharLabel.moveBelow(charsPanel, 14);
        createNewCharLabel.updateRect();
        createNewCharLabel.show();

        createNewCharLabel.onMouseButtonUp(new MouseButtonEventHandler((b,p) {
            auto c = new Character;
            c.name = "Character";
            auto defaultExpression = new CharacterExpression;
            defaultExpression.name = "default";
            defaultExpression.value = "Expression";
            c.expressions ~= defaultExpression;
            auto expression = new CharacterExpression;
            expression.name = "Expression";
            expression.value = "data/game/characters/Character/Expression.png";
            c.expressions ~= expression;
            characters ~= c;

            showExpressionView(c, settings);
        }));
    }

    void restyleButton(Button button, string buttonBackgroundColor, string buttonBackgroundBottomColor, string buttonBorderColor, string buttonTextColor)
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

    Component[] currentViewComponents;

    void clearCurrentView()
    {
        if (currentViewComponents && currentViewComponents.length)
        {
            foreach (currentViewComponent; currentViewComponents)
            {
                removeComponent(currentViewComponent);
            }

            currentViewComponents = [];
        }
    }

    void showExpressionView(Character character, GameSettings settings)
    {
        int offsetX = charsLine.x + charsLine.width + 14;
        clearCurrentView();

        foreach (c; characters)
        {
            c.nameValue = null;

            foreach (expression; c.expressions)
            {
                expression.nameValue = null;
                expression.valueValue = null;
            }
        }

        auto panel = new Panel(window);
        currentViewComponents ~= panel;
        panel.size = IntVector(window.width - (offsetX + 14), window.height - 28);
        panel.position = IntVector(offsetX, 14);
        panel.fillColor = getColorByRGB(0,0,0,150);
        addComponent(panel);

        auto scrollbarMessages = new ScrollBar(window, panel);
        currentViewComponents ~= scrollbarMessages;
        addComponent(scrollbarMessages);
        scrollbarMessages.isVertical = true;
        scrollbarMessages.fillColor = getColorByRGB(0,0,0,150);
        scrollbarMessages.borderColor = getColorByRGB(0,0,0,150);
        panel.scrollMargin = IntVector(0,cast(int)((cast(double)panel.height / 3.5) / 2));
        scrollbarMessages.position = IntVector(panel.x + panel.width, panel.y);
        scrollbarMessages.buttonScrollAmount = cast(int)((cast(double)panel.height / 3.5) / 2);
        scrollbarMessages.fontName = settings.defaultFont;
        scrollbarMessages.fontSize = 8;
        scrollbarMessages.buttonTextColor = textColor.getColorByHex;
        scrollbarMessages.createDecrementButton("▲", "◀");
        scrollbarMessages.createIncrementButton("▼", "▶");
        scrollbarMessages.size = IntVector(16, panel.height);

        scrollbarMessages.updateScrollView();

        auto characterNameTextBox = new TextBox(window);
        panel.addComponent(characterNameTextBox);
        characterNameTextBox.fontName = settings.defaultFont;
        characterNameTextBox.fontSize = 24;
        characterNameTextBox.size = IntVector((window.width / 4), 42);
        characterNameTextBox.position = IntVector(14, 14);
        characterNameTextBox.textColor = textColor.getColorByHex;
        characterNameTextBox.maxCharacters = 80;
        characterNameTextBox.textPadding = 8;
        characterNameTextBox.text = character.name.to!dstring;
        
        characterNameTextBox.defaultPaint.backgroundColor = textBoxColor.getColorByHex;
        characterNameTextBox.hoverPaint.backgroundColor = textBoxColor.getColorByHex.changeAlpha(220);
        characterNameTextBox.focusPaint.backgroundColor = textBoxColor.getColorByHex.changeAlpha(150);
        characterNameTextBox.defaultPaint.borderColor = textBoxBorderColor.getColorByHex;
        characterNameTextBox.hoverPaint.borderColor = textBoxBorderColor.getColorByHex;
        characterNameTextBox.focusPaint.borderColor = textBoxBorderColor.getColorByHex;
        characterNameTextBox.defaultPaint.shadowColor = textBoxColor.getColorByHex;
        characterNameTextBox.hoverPaint.shadowColor = textBoxColor.getColorByHex.changeAlpha(220);
        characterNameTextBox.focusPaint.shadowColor = textBoxColor.getColorByHex.changeAlpha(150);

        characterNameTextBox.restyle();
        characterNameTextBox.show();
        character.nameValue = characterNameTextBox;

        TextBox lastExpresionNameTextBox = characterNameTextBox;
        
        auto expressions = character.expressions.dup;
        sort(expressions);
        foreach (expression; expressions)
        {
            auto removeClosure = (Button b, string exp) { return () {
                b.onButtonClick(new MouseButtonEventHandler((b,p) {
                    character.expressions = character.expressions.filter!(e => e.name != exp).array;
                    showExpressionView(character, settings);
                }));
            };};

            auto expresionNameTextBox = new TextBox(window);
            panel.addComponent(expresionNameTextBox);
            expresionNameTextBox.fontName = settings.defaultFont;
            expresionNameTextBox.fontSize = 24;
            expresionNameTextBox.size = IntVector((window.width / 4), 42);
            expresionNameTextBox.moveBelow(lastExpresionNameTextBox, 14);
            lastExpresionNameTextBox = expresionNameTextBox;
            expresionNameTextBox.textColor = textColor.getColorByHex;
            expresionNameTextBox.maxCharacters = 80;
            expresionNameTextBox.textPadding = 8;
            expresionNameTextBox.text = expression.name.to!dstring;
            
            expresionNameTextBox.defaultPaint.backgroundColor = textBoxColor.getColorByHex;
            expresionNameTextBox.hoverPaint.backgroundColor = textBoxColor.getColorByHex.changeAlpha(220);
            expresionNameTextBox.focusPaint.backgroundColor = textBoxColor.getColorByHex.changeAlpha(150);
            expresionNameTextBox.defaultPaint.borderColor = textBoxBorderColor.getColorByHex;
            expresionNameTextBox.hoverPaint.borderColor = textBoxBorderColor.getColorByHex;
            expresionNameTextBox.focusPaint.borderColor = textBoxBorderColor.getColorByHex;
            expresionNameTextBox.defaultPaint.shadowColor = textBoxColor.getColorByHex;
            expresionNameTextBox.hoverPaint.shadowColor = textBoxColor.getColorByHex.changeAlpha(220);
            expresionNameTextBox.focusPaint.shadowColor = textBoxColor.getColorByHex.changeAlpha(150);

            expresionNameTextBox.restyle();
            expresionNameTextBox.show();
            expression.nameValue = expresionNameTextBox;

            auto expresionValueTextBox = new TextBox(window);
            panel.addComponent(expresionValueTextBox);
            expresionValueTextBox.fontName = settings.defaultFont;
            expresionValueTextBox.fontSize = 12;
            expresionValueTextBox.size = IntVector((window.width / 4), 42);
            expresionValueTextBox.moveRightOf(expresionNameTextBox, 14, true);
            expresionValueTextBox.textColor = textColor.getColorByHex;
            expresionValueTextBox.maxCharacters = 80;
            expresionValueTextBox.textPadding = 8;
            expresionValueTextBox.text = expression.value.to!dstring;
            
            expresionValueTextBox.defaultPaint.backgroundColor = textBoxColor.getColorByHex;
            expresionValueTextBox.hoverPaint.backgroundColor = textBoxColor.getColorByHex.changeAlpha(220);
            expresionValueTextBox.focusPaint.backgroundColor = textBoxColor.getColorByHex.changeAlpha(150);
            expresionValueTextBox.defaultPaint.borderColor = textBoxBorderColor.getColorByHex;
            expresionValueTextBox.hoverPaint.borderColor = textBoxBorderColor.getColorByHex;
            expresionValueTextBox.focusPaint.borderColor = textBoxBorderColor.getColorByHex;
            expresionValueTextBox.defaultPaint.shadowColor = textBoxColor.getColorByHex;
            expresionValueTextBox.hoverPaint.shadowColor = textBoxColor.getColorByHex.changeAlpha(220);
            expresionValueTextBox.focusPaint.shadowColor = textBoxColor.getColorByHex.changeAlpha(150);

            expresionValueTextBox.restyle();
            expresionValueTextBox.show();
            expression.valueValue = expresionValueTextBox;

            auto removeExpressionButton = new Button(window);
            panel.addComponent(removeExpressionButton);
            removeExpressionButton.size = IntVector(48, 48);
            removeExpressionButton.moveRightOf(expresionValueTextBox, 14, true);
            removeExpressionButton.fontName = settings.defaultFont;
            removeExpressionButton.fontSize = 22;
            removeExpressionButton.textColor = "000".getColorByHex;
            removeExpressionButton.text = "X";
            removeExpressionButton.fitToSize = false;
            removeExpressionButton.restyle();
            restyleButton(removeExpressionButton, "CB4335", "CB4335", "943126", buttonTextColor);

            removeClosure(removeExpressionButton, expression.name)();
        }

        {
            auto addClosure = (Button b) { return () {
                b.onButtonClick(new MouseButtonEventHandler((b,p) {
                    auto e = new CharacterExpression;
                    e.name = "";
                    e.value = "";
                    character.expressions ~= e;

                    showExpressionView(character, settings);
                }));
            };};

            auto saveClosure = (Button b) { return () {
                b.onButtonClick(new MouseButtonEventHandler((b,p) {
                    auto generated = generateCharactersOutput();

                    saveCharactersJson(_projectPath, generated); 

                    onInitialize(false);
                }));
            };};

            auto addCharacterExpressionButton = new Button(window);
            panel.addComponent(addCharacterExpressionButton);
            addCharacterExpressionButton.size = IntVector(48, 48);
            addCharacterExpressionButton.moveBelow(lastExpresionNameTextBox, 14);
            addCharacterExpressionButton.fontName = settings.defaultFont;
            addCharacterExpressionButton.fontSize = 22;
            addCharacterExpressionButton.textColor = "000".getColorByHex;
            addCharacterExpressionButton.text = "+";
            addCharacterExpressionButton.fitToSize = false;
            addCharacterExpressionButton.restyle();
            restyleButton(addCharacterExpressionButton, buttonBackgroundColor, buttonBackgroundBottomColor, buttonBorderColor, buttonTextColor);

            addClosure(addCharacterExpressionButton)();

            auto saveCharacterButton = new Button(window);
            panel.addComponent(saveCharacterButton);
            saveCharacterButton.size = IntVector(202, 48);
            saveCharacterButton.moveRightOf(addCharacterExpressionButton, 14, true);
            saveCharacterButton.fontName = settings.defaultFont;
            saveCharacterButton.fontSize = 22;
            saveCharacterButton.textColor = "000".getColorByHex;
            saveCharacterButton.text = "SAVE CHARACTER";
            saveCharacterButton.fitToSize = false;
            saveCharacterButton.restyle();
            restyleButton(saveCharacterButton, "28B463", "28B463", "28B463", buttonTextColor);

            saveClosure(saveCharacterButton)();
        }

        scrollbarMessages.updateScrollView();
        panel.makeScrollableWithWheel();
    }

    void showCreateView()
    {
        int offsetX = charsLine.x + charsLine.width + 14;
        clearCurrentView();
    }
}