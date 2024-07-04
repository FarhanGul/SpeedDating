--!Type(Module)

local fontSize
local colors

function self:ClientAwake()
    colors = {
        black = Color.new(20/255, 19/255, 23/255),
        darkGrey = Color.new(40/255, 39/255, 45/255),
        grey = Color.new(63/255, 62/255, 70/255),
        blue = Color.new(13/255, 166/255, 252/255),
        red = Color.new(249/255, 42/255, 65/255),
        white = Color.new(204/255, 202/255, 220/255),
        lightGrey = Color.new(125/255,124/255,136/255),
    }
    fontSize = {
        normal = 17,
        heading = 20
    }
end

function CreateTabs(options)
    local ve = VisualElement.new()
    ve:AddToClassList("HorizontalLayout")
    for i = 1 , #options do
        local button = UIButton.new()
        button.style.color = StyleColor.new(Color.clear)
        button:Add(CreateLabel(options[i].text,FontSize().normal,Color.white)) 
        button.style.borderBottomColor = StyleColor.new(Colors().blue)
        button:RegisterPressCallback(function()
            for j = 1 , ve.childCount do
                local child = ve:ElementAt(j-1)
                if(button == child) then
                    -- Select
                    child:ElementAt(0).style.color = StyleColor.new(Colors().blue)
                    child.style.borderBottomWidth = StyleFloat.new(3)
                else
                    -- Unselect
                    child:ElementAt(0).style.color = StyleColor.new(Colors().white)
                    child.style.borderBottomWidth =  StyleFloat.new(0)
                end
            end
            options[i].pressed()
        end)
        ve:Add(button)
        -- Select Default
        ve:ElementAt(0):ElementAt(0).style.color = StyleColor.new(Colors().blue)
        ve:ElementAt(0).style.borderBottomWidth = StyleFloat.new(3)
    end

    return ve
end

function CreateButton(text,onPressed,color,class)
    local button = UIButton.new()
    SetBackgroundColor(button, color)
    local label = CreateLabel(text,FontSize().normal, color == Color.clear and Colors().red or Colors().white)
    button:Add(label) 
    button:AddToClassList(class == nil and "DefaultButton" or class)
    button:RegisterPressCallback(onPressed)
    return button
end

function SetMargin(ve:VisualElement,amount)
    local scaledAmount = amount
    ve.style.marginTop = StyleLength.new(Length.new(scaledAmount))
    ve.style.marginRight = StyleLength.new(Length.new(scaledAmount))
    ve.style.marginBottom = StyleLength.new(Length.new(scaledAmount))
    ve.style.marginLeft = StyleLength.new(Length.new(scaledAmount))
end

function SetBackgroundColor(ve:VisualElement,color)
    ve.style.backgroundColor = StyleColor.new(color)
end

function SetRelativeSize(ve : VisualElement,w,h)
    if(w > -1) then ve.style.width = StyleLength.new(Length.Percent(w)) end
    if(h > -1) then ve.style.height = StyleLength.new(Length.Percent(h)) end
end

function SetSize(ve : VisualElement,w,h)
    if(w > -1) then ve.style.width = StyleLength.new(Length.new(w)) end
    if(h > -1) then ve.style.height = StyleLength.new(Length.new(h)) end
end

function RenderFullScreenPanel(root)
    root:Clear()
    local panel = VisualElement.new()
    SetBackgroundColor(panel, Colors().black)
    SetRelativeSize(panel, 100, 100)
    root:Add(panel)
    return panel
end

function CreateLabel(...)
    local args = {...}
    local text = args[1]
    local fontSize = args[2] == nil and FontSize().normal or args[2]
    local color = args[3] == nil and Colors().white or args[3]
    local label = UILabel.new()
    label:SetEmojiPrelocalizedText(text, false)
    label.style.color = StyleColor.new(color)
    label.style.fontSize = StyleLength.new(Length.new(fontSize))
    label:AddToClassList("DefaultLabel")
    return label
end

function FontSize()
    return fontSize
end

function Colors()
    return colors
end