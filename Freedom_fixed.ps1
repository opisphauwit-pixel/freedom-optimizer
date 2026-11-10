# Auto-Elevate to Administrator
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    $scriptPath = $MyInvocation.MyCommand.Path
    if ([string]::IsNullOrEmpty($scriptPath)) { $scriptPath = $PSCommandPath }
    if ($scriptPath) {
        try { Start-Process powershell.exe -ArgumentList "-ExecutionPolicy Bypass -WindowStyle Hidden -File `"$scriptPath`"" -Verb RunAs } catch {}
    }
    Exit
}

# Hide PowerShell Console Window
$code = @"
using System;
using System.Runtime.InteropServices;
public class Win32 {
    [DllImport("kernel32.dll")]
    public static extern IntPtr GetConsoleWindow();
    [DllImport("user32.dll")]
    public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
}
"@
Add-Type -TypeDefinition $code
try { [void][Win32]::ShowWindow([Win32]::GetConsoleWindow(), 0) } catch {}

Add-Type -AssemblyName PresentationFramework

# ========================================================
# KeyAuth License Configuration & Global Resources
# ========================================================
Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase

if (-not ("FreedomThemedMessageBox" -as [type])) {
    Add-Type -ReferencedAssemblies @("PresentationFramework", "PresentationCore", "WindowsBase", "System.Xaml") -TypeDefinition @'
using System;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Media;

public static class FreedomThemedMessageBox
{
    public static MessageBoxResult Show(string message, string caption)
    {
        return Show(message, caption, MessageBoxButton.OK, MessageBoxImage.Information);
    }

    public static MessageBoxResult Show(string message, string caption, MessageBoxButton buttons, MessageBoxImage image)
    {
        MessageBoxResult result = buttons == MessageBoxButton.YesNo ? MessageBoxResult.No : MessageBoxResult.Cancel;
        Window dialog = new Window
        {
            Title = caption,
            Width = 520,
            MinHeight = 250,
            MaxHeight = 560,
            SizeToContent = SizeToContent.Height,
            WindowStyle = WindowStyle.None,
            ResizeMode = ResizeMode.NoResize,
            WindowStartupLocation = WindowStartupLocation.CenterOwner,
            ShowInTaskbar = false,
            AllowsTransparency = true,
            Background = Brushes.Transparent
        };

        SolidColorBrush accent = image == MessageBoxImage.Error ? Brush("#EF4444") :
            image == MessageBoxImage.Warning ? Brush("#F59E0B") : Brush("#E11D2E");
        Border root = new Border
        {
            Background = Brush("#0B0809"),
            BorderBrush = Brush("#9F1724"),
            BorderThickness = new Thickness(1),
            CornerRadius = new CornerRadius(16),
            Effect = new System.Windows.Media.Effects.DropShadowEffect
            {
                BlurRadius = 28,
                ShadowDepth = 0,
                Opacity = 0.6,
                Color = Color.FromRgb(225, 29, 46)
            }
        };
        Grid layout = new Grid();
        layout.RowDefinitions.Add(new RowDefinition { Height = new GridLength(58) });
        layout.RowDefinitions.Add(new RowDefinition { Height = GridLength.Auto });
        layout.RowDefinitions.Add(new RowDefinition { Height = GridLength.Auto });
        Border header = new Border { Background = Brush("#120A0C"), CornerRadius = new CornerRadius(16, 16, 0, 0) };
        TextBlock brand = new TextBlock
        {
            Text = String.IsNullOrWhiteSpace(caption) ? "FREEDOM OPTIMIZER" : caption.ToUpperInvariant(),
            Foreground = Brush("#A1A1AA"),
            FontSize = 11,
            FontWeight = FontWeights.Bold,
            VerticalAlignment = VerticalAlignment.Center
        };
        Border status = new Border
        {
            Width = 9,
            Height = 9,
            Background = accent,
            CornerRadius = new CornerRadius(5),
            Margin = new Thickness(0, 0, 10, 0),
            VerticalAlignment = VerticalAlignment.Center
        };
        StackPanel brandRow = new StackPanel { Orientation = Orientation.Horizontal, VerticalAlignment = VerticalAlignment.Center };
        brandRow.Children.Add(status);
        brandRow.Children.Add(brand);
        header.Child = brandRow;
        header.Padding = new Thickness(20, 0, 20, 0);
        Grid.SetRow(header, 0);
        layout.Children.Add(header);

        StackPanel content = new StackPanel { Margin = new Thickness(24, 22, 24, 14) };
        TextBlock title = new TextBlock
        {
            Text = image == MessageBoxImage.Error ? "เกิดข้อผิดพลาด" :
                   image == MessageBoxImage.Warning ? "โปรดตรวจสอบ" : "ดำเนินการแล้ว",
            Foreground = Brushes.White,
            FontSize = 22,
            FontWeight = FontWeights.Bold,
            TextWrapping = TextWrapping.Wrap
        };
        content.Children.Add(title);
        TextBox body = new TextBox
        {
            Text = message ?? String.Empty,
            IsReadOnly = true,
            TextWrapping = TextWrapping.Wrap,
            AcceptsReturn = true,
            IsReadOnlyCaretVisible = true,
            Background = Brushes.Transparent,
            Foreground = Brush("#D4D4D8"),
            BorderThickness = new Thickness(0),
            FontSize = 13,
            Margin = new Thickness(0, 12, 0, 0),
            MaxHeight = 350,
            VerticalScrollBarVisibility = ScrollBarVisibility.Auto
        };
        content.Children.Add(body);
        Grid.SetRow(content, 1);
        layout.Children.Add(content);

        Border divider = new Border { Height = 1, Background = Brush("#281216"), Margin = new Thickness(24, 0, 24, 0) };
        Grid.SetRow(divider, 2);
        layout.Children.Add(divider);
        StackPanel buttonsRow = new StackPanel
        {
            Orientation = Orientation.Horizontal,
            HorizontalAlignment = HorizontalAlignment.Right,
            Margin = new Thickness(0, 15, 24, 20)
        };
        if (buttons == MessageBoxButton.YesNo)
        {
            Button no = CreateButton("ไม่", false);
            no.Margin = new Thickness(0, 0, 10, 0);
            no.Click += (sender, args) => { result = MessageBoxResult.No; dialog.Close(); };
            buttonsRow.Children.Add(no);
            Button yes = CreateButton("ใช่", true);
            yes.Click += (sender, args) => { result = MessageBoxResult.Yes; dialog.Close(); };
            buttonsRow.Children.Add(yes);
        }
        else
        {
            Button ok = CreateButton("ตกลง", true);
            ok.Click += (sender, args) => { result = MessageBoxResult.OK; dialog.Close(); };
            buttonsRow.Children.Add(ok);
        }
        dialog.Content = root;
        Grid outer = new Grid();
        outer.RowDefinitions.Add(new RowDefinition { Height = GridLength.Auto });
        outer.RowDefinitions.Add(new RowDefinition { Height = GridLength.Auto });
        Grid.SetRow(layout, 0);
        outer.Children.Add(layout);
        Grid.SetRow(buttonsRow, 1);
        outer.Children.Add(buttonsRow);
        root.Child = outer;
        header.MouseLeftButtonDown += (sender, args) => { if (args.ButtonState == System.Windows.Input.MouseButtonState.Pressed) dialog.DragMove(); };
        dialog.KeyDown += (sender, args) => { if (args.Key == System.Windows.Input.Key.Escape) dialog.Close(); };
        Window owner = Application.Current == null ? null : Application.Current.MainWindow;
        if (owner != null && owner != dialog && owner.IsVisible) dialog.Owner = owner;
        dialog.ShowDialog();
        return result;
    }

    private static SolidColorBrush Brush(string color)
    {
        return (SolidColorBrush)new BrushConverter().ConvertFromString(color);
    }

    private static Button CreateButton(string label, bool primary)
    {
        Button button = new Button
        {
            Content = label,
            Width = 110,
            Height = 38,
            Background = Brush(primary ? "#C9152A" : "#160C0E"),
            Foreground = Brushes.White,
            BorderBrush = Brush(primary ? "#C9152A" : "#4A1217"),
            BorderThickness = new Thickness(1),
            FontWeight = FontWeights.Bold,
            Cursor = System.Windows.Input.Cursors.Hand
        };
        FrameworkElementFactory border = new FrameworkElementFactory(typeof(Border));
        border.SetValue(Border.BackgroundProperty, new TemplateBindingExtension(Button.BackgroundProperty));
        border.SetValue(Border.BorderBrushProperty, new TemplateBindingExtension(Button.BorderBrushProperty));
        border.SetValue(Border.BorderThicknessProperty, new TemplateBindingExtension(Button.BorderThicknessProperty));
        border.SetValue(Border.CornerRadiusProperty, new CornerRadius(8));
        FrameworkElementFactory presenter = new FrameworkElementFactory(typeof(ContentPresenter));
        presenter.SetValue(ContentPresenter.HorizontalAlignmentProperty, HorizontalAlignment.Center);
        presenter.SetValue(ContentPresenter.VerticalAlignmentProperty, VerticalAlignment.Center);
        border.AppendChild(presenter);
        ControlTemplate template = new ControlTemplate(typeof(Button));
        template.VisualTree = border;
        button.Template = template;
        return button;
    }
}
'@
}

# Global Embedded Avatar ImageBrush
$avatarBase64 = "iVBORw0KGgoAAAANSUhEUgAAAgAAAAIACAYAAAD0eNT6AAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAAJcEhZcwAADsMAAA7DAcdvqGQAAP+lSURBVHhe7J0FmBbl18Y/pTvs7v7b3Y3d3d3Yid2KioqAiEFZdHd3dy61dC3bvdT5zu88e5aX9SUVBZ259lwz78Qzz8TOfZ98/k+n2SrJkUQSSSSRRBLJf0ZmqfxflopEEkkkkUQSSST/GclU+b+UmBWRRBJJJJFEEsm/X7ACRAQgkkgiiSSSSP5jEhGASCKJJJJIIvkPSkQAIokkkkgiieQ/KBEBiCSSSCKJJJL/oEQEIJJIIokkkkj+gxIRgEgiiSSSSCL5D0pEACKJJJJIIonkPygRAYgkkkgiiSSS/6BEBCCSSCKJJJJI/oMSEYBIIokkkkgi+Q9KRAAiieS/IhUqVJASJUrE3RZJJJH85yQiAJFE8m+UsmXLyjnnnCOXX3653HPPPfL444/LnXfeKeeee65UqlxZSpUqFfe4SCKJ5D8jEQGIJJJ/m6DlX3rJJdLkp8YmA/r1l9WrVknb1m3kvXfelZpP1ZSnnnxKjj76aKlSpUrcNiKJJJJ/vUQEIJJI/k0CoJ9/3vny7NPPyIfvvS/t27aTGdMThGnwwEFGAn5o9L28+/Y78sRjj0uNGpfKbrvtJmXKlLHjd9ppp/XaK/47kkgi+ddIRAAiieTfIHvutZccdthhcu8998j33zWSWq++Jh3bd5CZCTMkLSXVCECfXr3lx+9/kJHDR5hV4LNPa8tDDz4oF154oRKBGnLooYfKySefLMcdd5wcccQRctJJJ8kJJ5wgF1xwgdx0001y//33y7HHHisHHnig7Vu1atWtJggcV65cOXNVuDuC37vuuqvsvPPOf9g/kkgi+cslIgCRRLIjCwB66aWXymOPPyZff/21dO3cRWp/8qmB++iRo2T40GGSnLTCCMCSRYulV4+eZhGYMG68fPDe+/LIQw/Lo489auB+9tlny7XXXitvv/22vPbaa0XzOnXqSOfOneW3336TN998U9544w156KGH5JRTTikC79KlS5vrAfDefffdjSDst99+cv7558tRRx1lZGGPPfaQ8uXLyz777CNXXXWV3HDDDXL99dfL3XffLc8995y88MILFqtAX44//nhr8+KLL5YrrrjC2oCI3HrrrXLllVdK5cqV/3AvIokkki2SiABEEsmOIoD9LrvsIhUrVjSzPWD5+uuvy6+//iojR46UQYMGSeuWraTO519I/W/qmfl/6OAhBvyrV66SVQUrZfbMWdK5Yydp2OBbqVf3G/lC933ppZcMhAkSfPfdd6VRo0by448/yg8//CBNmjSRb7/91n63bdtW+vTpI59++qk888wzBsZYD+644w4LNASYEYjIN998YwJpoL0nn3xSvvjiCzu2YcOG0r59e+t306ZNpVmzZvb7l19+ke+//15atWolzZs3N7LBMT/99JOdn/1Y36lTJyMg+++/v92LePcqkkgi2aREBCCSSLZ3QXPGLA/g3nzzzfLggw/K888/b8AIiA4dOlQSExMladlyA/cunTrbfNSIkTJh7DizCqxYniQL5y+Qnt17mIugXZu28vuvv0n9evWl9mefyccffyy///67gTckoHHjxgbIHTp0kO7duxvBGDZsmPTr188AHWHfDz74wCwEkATk/fffN4Du27ev9OrVy47/+eefDcABd4AeawLCNtqk7QEDBsj06dNl1qxZdr6WLVtaOyx369bNjqfNhQsX2v5du3aVWrVqmQXhkEMOiXvfIokkko1KRAAiiWR7klifOub1a665Rj788EOpXbu2gf1TTz1lGnSbNm0MGNH6x40bJzNmzpDly5bJ4oWLZPSo0dL4x58kcfYcycvNlRnTZ0jKimQz+zdr0lQaKOj36NZd2rRqLS1atJAO7TsYmA8cONAAHuD/7rvvpF27dkYKELZhAXCt3gGd4z755BPT5LEWfPnll7Ye0IckcCxkgvY+U6KBsD9kAW1+8ODBdk7Anyk/P19ycnJkzJgx1gZA36NHDyMD9Gvq1KnWDwgE63FTcI8uuugiOfzww831gOug+H305erVq0u1atWKfiPEHhx00EFy+umnm9sidlskkfyLJSIAkUSyvQiBd/jFAbPzzjvPTPIANAAKAQD0AeJRo0aZ5gwYLliwQCZNmmTz7KwsWbNqtRKB5TJy2HBJT0mVXAXTnKxsKcjLl/lz55kFgOBAsgE6tGsvAwcMlA4dO5g2Pnv2bBkyZIgBLIDdunVrA16WAd/evXsboHN+QPytt96Szz//3PaHnOAyALDZF3Cnvywzx6zfoEEDefnll81KwL6jR4+29iAA8+fPlzVr1hgJ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"
try {
    $avatarBytes = [System.Convert]::FromBase64String($avatarBase64)
    $avatarMs = New-Object System.IO.MemoryStream(,$avatarBytes)
    $avatarImg = New-Object System.Windows.Media.Imaging.BitmapImage
    $avatarImg.BeginInit()
    $avatarImg.CacheOption = [System.Windows.Media.Imaging.BitmapCacheOption]::OnLoad
    $avatarImg.StreamSource = $avatarMs
    $avatarImg.EndInit()
    $avatarImg.Freeze()
    $globalAvatarBrush = New-Object System.Windows.Media.ImageBrush($avatarImg)
    $globalAvatarBrush.Stretch = "UniformToFill"
} catch {
    $globalAvatarBrush = $null
}

[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Freedom" Height="740" Width="1150"
        WindowStyle="None" AllowsTransparency="True" Background="Transparent"
        WindowStartupLocation="CenterScreen">
    
        <Window.Resources>
        <!-- 3D Dimensional Red & Dark Gradients -->
        <LinearGradientBrush x:Key="AccentGradient" StartPoint="0,0" EndPoint="1,1">
            <GradientStop Color="#ff2a3f" Offset="0.0"/>
            <GradientStop Color="#dc1428" Offset="0.5"/>
            <GradientStop Color="#800a12" Offset="1.0"/>
        </LinearGradientBrush>
        <LinearGradientBrush x:Key="CardGradient" StartPoint="0,0" EndPoint="0,1">
            <GradientStop Color="#18080a" Offset="0.0"/>
            <GradientStop Color="#0c0304" Offset="1.0"/>
        </LinearGradientBrush>
                <Style TargetType="Button" x:Key="PremiumButton">
            <Setter Property="Background">
                <Setter.Value>
                    <LinearGradientBrush StartPoint="0,0" EndPoint="0,1">
                        <GradientStop Color="#ff3347" Offset="0.0"/>
                        <GradientStop Color="#dc1428" Offset="0.5"/>
                        <GradientStop Color="#990c19" Offset="1.0"/>
                    </LinearGradientBrush>
                </Setter.Value>
            </Setter>
            <Setter Property="Foreground" Value="#ffffff"/>
            <Setter Property="FontWeight" Value="Bold"/>
            <Setter Property="FontSize" Value="14"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border Background="{TemplateBinding Background}" CornerRadius="10" BorderThickness="1" BorderBrush="#ff6b7a">
                            <Border.Effect>
                                <DropShadowEffect BlurRadius="16" ShadowDepth="4" Opacity="0.55" Color="#dc2626"/>
                            </Border.Effect>
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center" Margin="10,0"/>
                        </Border>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
            <Style.Triggers>
                <Trigger Property="IsMouseOver" Value="True">
                    <Setter Property="Opacity" Value="0.92"/>
                    <Setter Property="Background">
                        <Setter.Value>
                            <LinearGradientBrush StartPoint="0,0" EndPoint="0,1">
                                <GradientStop Color="#ff4d60" Offset="0.0"/>
                                <GradientStop Color="#ef1e33" Offset="0.5"/>
                                <GradientStop Color="#b31020" Offset="1.0"/>
                            </LinearGradientBrush>
                        </Setter.Value>
                    </Setter>
                </Trigger>
                <Trigger Property="IsPressed" Value="True">
                    <Setter Property="Opacity" Value="0.75"/>
                </Trigger>
            </Style.Triggers>
        </Style>

                <Style TargetType="Button" x:Key="SecondaryButton">
            <Setter Property="Background">
                <Setter.Value>
                    <LinearGradientBrush StartPoint="0,0" EndPoint="0,1">
                        <GradientStop Color="#1c090c" Offset="0"/>
                        <GradientStop Color="#0f0305" Offset="1"/>
                    </LinearGradientBrush>
                </Setter.Value>
            </Setter>
            <Setter Property="Foreground" Value="#eeeeee"/>
            <Setter Property="FontWeight" Value="SemiBold"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border Background="{TemplateBinding Background}" BorderBrush="#4a1217" BorderThickness="1" CornerRadius="10">
                            <Border.Effect>
                                <DropShadowEffect BlurRadius="8" ShadowDepth="3" Opacity="0.45" Color="#000000"/>
                            </Border.Effect>
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center" Margin="10,0"/>
                        </Border>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
            <Style.Triggers>
                <Trigger Property="IsMouseOver" Value="True">
                    <Setter Property="Background">
                        <Setter.Value>
                            <LinearGradientBrush StartPoint="0,0" EndPoint="0,1">
                                <GradientStop Color="#2f0e13" Offset="0"/>
                                <GradientStop Color="#180507" Offset="1"/>
                            </LinearGradientBrush>
                        </Setter.Value>
                    </Setter>
                    <Setter Property="BorderBrush" Value="#ff2a3f"/>
                </Trigger>
                <Trigger Property="IsPressed" Value="True">
                    <Setter Property="Opacity" Value="0.7"/>
                </Trigger>
            </Style.Triggers>
        </Style>

                <Style TargetType="Button" x:Key="MenuButton">
            <Setter Property="Background" Value="Transparent"/>
            <Setter Property="Foreground" Value="#8c8c96"/>
            <Setter Property="Height" Value="48"/>
            <Setter Property="FontSize" Value="14"/>
            <Setter Property="FontWeight" Value="Medium"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border Background="{TemplateBinding Background}" CornerRadius="6" Margin="10,2">
                            <ContentPresenter HorizontalAlignment="Left" VerticalAlignment="Center" Margin="20,0,0,0"/>
                        </Border>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
            <Style.Triggers>
                <Trigger Property="IsMouseOver" Value="True">
                    <Setter Property="Background" Value="#1d070a"/>
                    <Setter Property="Foreground" Value="#ff4d5e"/>
                </Trigger>
            </Style.Triggers>
        </Style>

        <Style TargetType="Button" x:Key="ActiveMenuButton" BasedOn="{StaticResource MenuButton}">
            <Setter Property="Background">
                <Setter.Value>
                    <LinearGradientBrush StartPoint="0,0" EndPoint="1,0">
                        <GradientStop Color="#330b10" Offset="0"/>
                        <GradientStop Color="#180406" Offset="1"/>
                    </LinearGradientBrush>
                </Setter.Value>
            </Setter>
            <Setter Property="Foreground" Value="White"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border Background="{TemplateBinding Background}" BorderBrush="#5e141a" BorderThickness="1" CornerRadius="6" Margin="10,2">
                            <Border.Effect>
                                <DropShadowEffect BlurRadius="12" ShadowDepth="2" Opacity="0.45" Color="#dc2626"/>
                            </Border.Effect>
                            <Grid>
                                <Rectangle Width="4" Height="26" Fill="{StaticResource AccentGradient}" HorizontalAlignment="Left" RadiusX="2" RadiusY="2" Margin="0"/>
                                <ContentPresenter HorizontalAlignment="Left" VerticalAlignment="Center" Margin="20,0,0,0"/>
                            </Grid>
                        </Border>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <Style TargetType="Button" x:Key="WindowControlButton">
            <Setter Property="Background" Value="Transparent"/>
            <Setter Property="Foreground" Value="#64748b"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border Background="{TemplateBinding Background}">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
            <Style.Triggers>
                <Trigger Property="IsMouseOver" Value="True">
                    <Setter Property="Background" Value="#27272a"/>
                    <Setter Property="Foreground" Value="White"/>
                </Trigger>
            </Style.Triggers>
        </Style>
        <Style TargetType="Button" x:Key="CloseButton" BasedOn="{StaticResource WindowControlButton}">
            <Style.Triggers>
                <Trigger Property="IsMouseOver" Value="True">
                    <Setter Property="Background" Value="#e60012"/>
                    <Setter Property="Foreground" Value="White"/>
                </Trigger>
            </Style.Triggers>
        </Style>
    </Window.Resources>

    <Window.Triggers>
        <EventTrigger RoutedEvent="Window.Loaded">
            <BeginStoryboard>
                <Storyboard>
                    <DoubleAnimation Storyboard.TargetProperty="Opacity" From="0.0" To="1.0" Duration="0:0:0.6"/>
                </Storyboard>
            </BeginStoryboard>
        </EventTrigger>
    </Window.Triggers>

    <Border CornerRadius="14" BorderThickness="1.5" BorderBrush="#5e141a">
        <Border.Background>
            <LinearGradientBrush StartPoint="0,0" EndPoint="1,1">
                <GradientStop Color="#090304" Offset="0"/>
                <GradientStop Color="#120507" Offset="0.5"/>
                <GradientStop Color="#060202" Offset="1"/>
            </LinearGradientBrush>
        </Border.Background>
        <Border.Effect>
            <DropShadowEffect BlurRadius="32" ShadowDepth="0" Opacity="0.65" Color="#dc2626"/>
        </Border.Effect>
        <Grid>
            <Grid.RowDefinitions>
                <RowDefinition Height="40"/>
                <RowDefinition Height="*"/>
            </Grid.RowDefinitions>
            
            <Grid Grid.Row="0" Background="Transparent" x:Name="TitleBar">
                <StackPanel Orientation="Horizontal" VerticalAlignment="Center" Margin="20,0,0,0">
                    <Ellipse Width="8" Height="8" Fill="{StaticResource AccentGradient}"/>
                    <TextBlock Text="Freedom" Foreground="#ddd" FontWeight="SemiBold" Margin="12,0,0,0" FontSize="12" FontFamily="Segoe UI"/>
                </StackPanel>
                <StackPanel Orientation="Horizontal" HorizontalAlignment="Right" VerticalAlignment="Stretch">
                    <Button Content="—" Width="50" Style="{StaticResource WindowControlButton}" FontSize="12" x:Name="BtnMinimize"/>
                    <Button Content="✕" Width="50" Style="{StaticResource CloseButton}" FontSize="12" x:Name="BtnClose"/>
                </StackPanel>
            </Grid>

            <Grid Grid.Row="1">
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="260"/>
                    <ColumnDefinition Width="*"/>
                </Grid.ColumnDefinitions>

                <Border Grid.Column="0" Background="#080405" BorderThickness="0,0,1,0" BorderBrush="#4a1217" CornerRadius="0,0,0,14">
                    <Grid>
                        <Grid.RowDefinitions>
                            <RowDefinition Height="Auto"/>
                            <RowDefinition Height="*"/>
                            <RowDefinition Height="Auto"/>
                        </Grid.RowDefinitions>
                        
                        <StackPanel Grid.Row="0">
                            <Ellipse x:Name="ProfileImage" Width="96" Height="96" Fill="#140608" Margin="0,35,0,15">
                                <Ellipse.Stroke>
                                    <LinearGradientBrush StartPoint="0,0" EndPoint="1,1">
                                        <GradientStop Color="#ff3347" Offset="0"/>
                                        <GradientStop Color="#dc1428" Offset="0.5"/>
                                        <GradientStop Color="#540b13" Offset="1"/>
                                    </LinearGradientBrush>
                                </Ellipse.Stroke>
                                <Ellipse.StrokeThickness>2.5</Ellipse.StrokeThickness>
                                <Ellipse.Effect>
                                    <DropShadowEffect BlurRadius="22" ShadowDepth="0" Opacity="0.75" Color="#dc2626"/>
                                </Ellipse.Effect>
                            </Ellipse>
                            <TextBlock Text="Freedom" Foreground="White" FontWeight="Bold" FontSize="20" HorizontalAlignment="Center"/>
                            <TextBlock Text="PREMIUM OPTIMIZER" Foreground="#ff3b4f" FontSize="11" FontWeight="Bold" HorizontalAlignment="Center" Margin="0,6,0,35"/>
                        </StackPanel>

                        <StackPanel Grid.Row="1" Margin="0,0,0,0">
                            <Button x:Name="BtnNavDashboard" Style="{StaticResource ActiveMenuButton}">
                                <StackPanel Orientation="Horizontal">
                                    <TextBlock FontFamily="Segoe MDL2 Assets" Text="&#xE80F;" FontSize="16" Width="40" VerticalAlignment="Center" Margin="0,-2,0,0"/>
                                    <TextBlock Text="Dashboard" VerticalAlignment="Center"/>
                                </StackPanel>
                            </Button>
                            <Button x:Name="BtnNavCPU" Style="{StaticResource MenuButton}">
                                <StackPanel Orientation="Horizontal">
                                    <TextBlock FontFamily="Segoe MDL2 Assets" Text="&#xE945;" FontSize="16" Width="40" VerticalAlignment="Center" Margin="0,-2,0,0"/>
                                    <TextBlock Text="Win32 / Gpedit" VerticalAlignment="Center"/>
                                </StackPanel>
                            </Button>
                            <Button x:Name="BtnNavInput" Style="{StaticResource MenuButton}">
                                <StackPanel Orientation="Horizontal">
                                    <TextBlock FontFamily="Segoe MDL2 Assets" Text="&#xE962;" FontSize="16" Width="40" VerticalAlignment="Center" Margin="0,-2,0,0"/>
                                    <TextBlock Text="Input" VerticalAlignment="Center"/>
                                </StackPanel>
                            </Button>
                            <Button x:Name="BtnNavNetwork" Style="{StaticResource MenuButton}">
                                <StackPanel Orientation="Horizontal">
                                    <TextBlock FontFamily="Segoe MDL2 Assets" Text="&#xE774;" FontSize="16" Width="40" VerticalAlignment="Center" Margin="0,-2,0,0"/>
                                    <TextBlock Text="Network" VerticalAlignment="Center"/>
                                </StackPanel>
                            </Button>
                            <Button x:Name="BtnNavPower" Style="{StaticResource MenuButton}">
                                <StackPanel Orientation="Horizontal">
                                    <TextBlock FontFamily="Segoe MDL2 Assets" Text="&#xE850;" FontSize="16" Width="40" VerticalAlignment="Center" Margin="0,-2,0,0"/>
                                    <TextBlock Text="Power / Timer" VerticalAlignment="Center"/>
                                </StackPanel>
                            </Button>
                            <Button x:Name="BtnNavTools" Style="{StaticResource MenuButton}">
                                <StackPanel Orientation="Horizontal">
                                    <TextBlock FontFamily="Segoe MDL2 Assets" Text="&#xE8FA;" FontSize="16" Width="40" VerticalAlignment="Center" Margin="0,-2,0,0"/>
                                    <TextBlock Text="Tools" VerticalAlignment="Center"/>
                                </StackPanel>
                            </Button>
                            <Button x:Name="BtnNavBoost" Style="{StaticResource MenuButton}">
                                <StackPanel Orientation="Horizontal">
                                    <TextBlock FontFamily="Segoe MDL2 Assets" Text="&#xE945;" FontSize="16" Width="40" VerticalAlignment="Center" Margin="0,-2,0,0"/>
                                    <TextBlock Text="Boost" VerticalAlignment="Center"/>
                                </StackPanel>
                            </Button>
                            <Button x:Name="BtnNavRestore" Style="{StaticResource MenuButton}">
                                <StackPanel Orientation="Horizontal">
                                    <TextBlock FontFamily="Segoe MDL2 Assets" Text="&#xE72C;" FontSize="16" Width="40" VerticalAlignment="Center" Margin="0,-2,0,0"/>
                                    <TextBlock Text="Restore" VerticalAlignment="Center"/>
                                </StackPanel>
                            </Button>
                        </StackPanel>
                        
                        <Border x:Name="SidebarImage" Visibility="Collapsed" Grid.Row="2" Height="140" Background="#121215" Margin="20,20,20,25" CornerRadius="10" BorderThickness="1" BorderBrush="#4a1217">
                            <TextBlock x:Name="SidebarPlaceholderText" Text="[Image Placeholder]" Foreground="#444" HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                    </Grid>
                </Border>

                <!-- VIEWS CONTAINER -->
                <Grid Grid.Column="1" Margin="45,35,45,35">
                    <Grid.RowDefinitions>
                        <RowDefinition Height="*"/>
                        <RowDefinition Height="Auto"/>
                    </Grid.RowDefinitions>

                    <Grid Grid.Row="0">
                        <!-- VIEW 1: DASHBOARD -->
                        <Grid x:Name="ViewDashboard" Visibility="Visible">
                            <Grid.RowDefinitions>
                                <RowDefinition Height="Auto"/>
                                <RowDefinition Height="Auto"/>
                                <RowDefinition Height="*"/>
                            </Grid.RowDefinitions>

                            <StackPanel Grid.Row="0" Margin="0,0,0,20">
                                <TextBlock Text="Dashboard" Foreground="White" FontSize="30" FontWeight="Bold"/>
                                <TextBlock Text="ภาพรวมระบบ และการตั้งค่าด่วน" Foreground="#a1a1aa" FontSize="15" Margin="0,6,0,0"/>
                            </StackPanel>

                            <Border x:Name="BannerImage" Grid.Row="1" Height="140" CornerRadius="12" Margin="0,0,0,20" BorderThickness="1.5" BorderBrush="#78141f">
                                <Border.Background>
                                    <LinearGradientBrush StartPoint="0,0" EndPoint="1,1">
                                        <GradientStop Color="#3a0b12" Offset="0.0"/>
                                        <GradientStop Color="#1a0407" Offset="0.45"/>
                                        <GradientStop Color="#080203" Offset="1.0"/>
                                    </LinearGradientBrush>
                                </Border.Background>
                                <Border.Effect>
                                    <DropShadowEffect BlurRadius="25" ShadowDepth="8" Opacity="0.55" Color="#dc2626"/>
                                </Border.Effect>
                                <Grid>
                                    <!-- 3D Red Tech Stripes / Lines Pattern -->
                                    <Canvas IsHitTestVisible="False" ClipToBounds="True">
                                        <Polygon Points="480,-20 520,-20 420,160 380,160" Fill="#dc2626" Opacity="0.12"/>
                                        <Polygon Points="550,-20 575,-20 475,160 450,160" Fill="#ff2a3f" Opacity="0.09"/>
                                        <Polygon Points="610,-20 670,-20 570,160 510,160" Fill="#dc2626" Opacity="0.15"/>
                                    </Canvas>
                                    <StackPanel Orientation="Horizontal" VerticalAlignment="Center" Margin="40,0">
                                        <Rectangle Width="5" Height="65" Fill="{StaticResource AccentGradient}" RadiusX="2.5" RadiusY="2.5" Margin="0,0,22,0">
                                            <Rectangle.Effect>
                                                <DropShadowEffect BlurRadius="14" ShadowDepth="0" Opacity="0.8" Color="#ff2a3f"/>
                                            </Rectangle.Effect>
                                        </Rectangle>
                                        <StackPanel VerticalAlignment="Center">
                                            <TextBlock Text="Freedom" Foreground="White" FontSize="42" FontWeight="Black">
                                                <TextBlock.Effect>
                                                    <DropShadowEffect BlurRadius="12" ShadowDepth="2" Opacity="0.5" Color="#dc2626"/>
                                                </TextBlock.Effect>
                                            </TextBlock>
                                            <TextBlock Text="Freedom TOOLBOX | HIGH PERFORMANCE OPTIMIZER" Foreground="#ff5263" FontSize="13" Margin="0,6,0,0" FontWeight="Bold"/>
                                        </StackPanel>
                                    </StackPanel>
                                </Grid>
                            </Border>

                            <Grid Grid.Row="2">
                                <Grid.RowDefinitions>
                                    <RowDefinition Height="Auto"/>
                                    <RowDefinition Height="Auto"/>
                                </Grid.RowDefinitions>
                                <Grid.ColumnDefinitions>
                                    <ColumnDefinition Width="*"/>
                                    <ColumnDefinition Width="*"/>
                                </Grid.ColumnDefinitions>

                                <!-- SYSTEM -->
                                <Border Grid.Row="0" Grid.Column="0" Background="{StaticResource CardGradient}" CornerRadius="12" Margin="0,0,15,15" Padding="25" BorderThickness="1" BorderBrush="#4a1217">
                                    <Border.Effect>
                                        <DropShadowEffect BlurRadius="18" ShadowDepth="6" Opacity="0.45" Color="#000000"/>
                                    </Border.Effect>
                                    <StackPanel>
                                        <StackPanel Orientation="Horizontal" Margin="0,0,0,20">
                                            <Rectangle Width="4" Height="18" Fill="{StaticResource AccentGradient}" Margin="0,0,12,0" RadiusX="2" RadiusY="2"/>
                                            <TextBlock Text="SYSTEM" Foreground="White" FontWeight="Bold" FontSize="16"/>
                                        </StackPanel>
                                        <TextBlock x:Name="SysOs" Text="OS: Loading..." Foreground="#a1a1aa" Margin="0,4" FontSize="14"/>
                                        <TextBlock x:Name="SysCpu" Text="CPU: Loading..." Foreground="#a1a1aa" Margin="0,4" FontSize="14"/>
                                        <TextBlock x:Name="SysRam" Text="RAM: Loading..." Foreground="#a1a1aa" Margin="0,4" FontSize="14"/>
                                        <TextBlock x:Name="SysHwid" Text="HWID: Loading..." Foreground="#a1a1aa" Margin="0,4" FontSize="14"/>
                                    </StackPanel>
                                </Border>

                                <!-- QUICK APPLY -->
                                <Border Grid.Row="0" Grid.Column="1" Background="{StaticResource CardGradient}" CornerRadius="12" Margin="15,0,0,15" Padding="25" BorderThickness="1" BorderBrush="#4a1217">
                                    <Border.Effect>
                                        <DropShadowEffect BlurRadius="18" ShadowDepth="6" Opacity="0.45" Color="#000000"/>
                                    </Border.Effect>
                                    <StackPanel>
                                        <StackPanel Orientation="Horizontal" Margin="0,0,0,20">
                                            <Rectangle Width="4" Height="18" Fill="{StaticResource AccentGradient}" Margin="0,0,12,0" RadiusX="2" RadiusY="2"/>
                                            <TextBlock Text="Set All (แนะนำ)" Foreground="White" FontWeight="Bold" FontSize="16"/>
                                        </StackPanel>
                                        <TextBlock Text="ตั้งค่า FiveM QoS/DSCP, Windows Game Mode, Responsiveness/MMCSS, TCP, active physical adapter และ Power Plan สำหรับเล่นเกม พร้อม Timer Service เฉพาะช่วง FiveM เปิดอยู่" Foreground="#a1a1aa" Margin="0,0,0,20" FontSize="14" TextWrapping="Wrap"/>
                                        <Button x:Name="BtnApplyRec" Style="{StaticResource PremiumButton}" Height="45">
                                            <StackPanel Orientation="Horizontal">
                                                <TextBlock FontFamily="Segoe MDL2 Assets" Text="&#xE93E;" FontSize="16" Margin="0,0,8,0" VerticalAlignment="Center"/>
                                                <TextBlock Text="APPLY ALLSET" VerticalAlignment="Center" FontWeight="Bold"/>
                                            </StackPanel>
                                        </Button>
                                    </StackPanel>
                                </Border>

                                <!-- STATUS -->
                                <Border Grid.Row="1" Grid.ColumnSpan="2" Background="{StaticResource CardGradient}" CornerRadius="12" Margin="0,0,0,15" Padding="25" BorderThickness="1" BorderBrush="#4a1217">
                                    <Border.Effect>
                                        <DropShadowEffect BlurRadius="18" ShadowDepth="6" Opacity="0.45" Color="#000000"/>
                                    </Border.Effect>
                                    <Grid>
                                        <Grid.ColumnDefinitions>
                                            <ColumnDefinition Width="*"/>
                                            <ColumnDefinition Width="Auto"/>
                                        </Grid.ColumnDefinitions>
                                        <StackPanel Grid.Column="0">
                                            <StackPanel Orientation="Horizontal" Margin="0,0,0,20">
                                                <Rectangle Width="4" Height="18" Fill="{StaticResource AccentGradient}" Margin="0,0,12,0" RadiusX="2" RadiusY="2"/>
                                                <TextBlock Text="STATUS" Foreground="White" FontWeight="Bold" FontSize="16"/>
                                            </StackPanel>
                                            <WrapPanel>
                                                <TextBlock x:Name="StatusPriority" Text="Win32PrioritySeparation: Unknown" Foreground="#a1a1aa" Margin="0,0,35,8" FontSize="14"/>
                                                <TextBlock x:Name="StatusQos" Text="QoS FiveM: Unknown" Foreground="#a1a1aa" Margin="0,0,35,8" FontSize="14"/>
                                                <TextBlock x:Name="StatusTimer" Text="Timer Service: Unknown" Foreground="#a1a1aa" Margin="0,0,35,8" FontSize="14"/>
                                                <TextBlock x:Name="StatusPlan" Text="Power Plan: Unknown" Foreground="#a1a1aa" Margin="0,0,35,8" FontSize="14"/>
                                            </WrapPanel>
                                        </StackPanel>
                                        <Button x:Name="BtnRefreshStatus" Grid.Column="1" Style="{StaticResource SecondaryButton}" Width="130" Height="42" VerticalAlignment="Center" Margin="15,0,0,0">
                                            <StackPanel Orientation="Horizontal">
                                                <TextBlock FontFamily="Segoe MDL2 Assets" Text="&#xE72C;" FontSize="14" Margin="0,0,8,0" VerticalAlignment="Center"/>
                                                <TextBlock Text="REFRESH" VerticalAlignment="Center" FontWeight="Bold"/>
                                            </StackPanel>
                                        </Button>
                                    </Grid>
                                </Border>
                            </Grid>
                        </Grid>
                        
                        <!-- VIEW 2: CPU / PRIORITY -->
                        <Grid x:Name="ViewCPU" Visibility="Collapsed">
                            <Grid.RowDefinitions>
                                <RowDefinition Height="Auto"/>
                                <RowDefinition Height="*"/>
                            </Grid.RowDefinitions>
                            <StackPanel Grid.Row="0" Margin="0,0,0,25">
                                <TextBlock Text="Win32 and Gpedit" Foreground="White" FontSize="30" FontWeight="Bold"/>
                                <TextBlock Text="ค่าขาว 100%" Foreground="#a1a1aa" FontSize="15" Margin="0,6,0,0"/>
                            </StackPanel>
                            
                            <ScrollViewer Grid.Row="1" VerticalScrollBarVisibility="Auto">
                                <StackPanel>
                                    <Border Background="{StaticResource CardGradient}" CornerRadius="12" Margin="0,0,0,20" Padding="30" BorderThickness="1" BorderBrush="#4a1217">
                                        <StackPanel>
                                            <StackPanel Orientation="Horizontal" Margin="0,0,0,20">
                                                <Rectangle Width="4" Height="18" Fill="{StaticResource AccentGradient}" Margin="0,0,12,0" RadiusX="2" RadiusY="2"/>
                                                <TextBlock Text="Win32 Priority Separation" Foreground="White" FontWeight="Bold" FontSize="16"/>
                                            </StackPanel>
                                            <TextBlock Text="เลือกค่าที่เหมาะสมกับสเปคคอมพิวเตอร์ของคุณเพื่อประสิทธิภาพสูงสุดใน FiveM" Foreground="#a1a1aa" Margin="0,0,0,20"/>
                                            <UniformGrid Columns="3" Rows="2" HorizontalAlignment="Stretch">
                                                <Button x:Name="BtnCpu26" Style="{StaticResource SecondaryButton}" Height="75" Margin="6">
                                                    <StackPanel VerticalAlignment="Center">
                                                        <TextBlock x:Name="TxtTitle26" Text="0x26" FontSize="17" FontWeight="Bold" HorizontalAlignment="Center" Foreground="White"/>
                                                        <TextBlock x:Name="TxtSub26" Text="Fps+inputlag" FontSize="12" Foreground="#a1a1aa" HorizontalAlignment="Center" Margin="0,2,0,0"/>
                                                        <TextBlock x:Name="TxtStatus26" Text="Successfully!" FontSize="11" FontWeight="Bold" Foreground="#e4e4e7" HorizontalAlignment="Center" Margin="0,2,0,0" Visibility="Collapsed"/>
                                                    </StackPanel>
                                                </Button>
                                                <Button x:Name="BtnCpu28" Style="{StaticResource SecondaryButton}" Height="75" Margin="6">
                                                    <StackPanel VerticalAlignment="Center">
                                                        <TextBlock x:Name="TxtTitle28" Text="0x28" FontSize="17" FontWeight="Bold" HorizontalAlignment="Center" Foreground="White"/>
                                                        <TextBlock x:Name="TxtSub28" Text="Inputlag" FontSize="12" Foreground="#a1a1aa" HorizontalAlignment="Center" Margin="0,2,0,0"/>
                                                        <TextBlock x:Name="TxtStatus28" Text="Successfully!" FontSize="11" FontWeight="Bold" Foreground="#e4e4e7" HorizontalAlignment="Center" Margin="0,2,0,0" Visibility="Collapsed"/>
                                                    </StackPanel>
                                                </Button>
                                                <Button x:Name="BtnCpu2A" Style="{StaticResource SecondaryButton}" Height="75" Margin="6">
                                                    <StackPanel VerticalAlignment="Center">
                                                        <TextBlock x:Name="TxtTitle2A" Text="0x2A" FontSize="17" FontWeight="Bold" HorizontalAlignment="Center" Foreground="White"/>
                                                        <TextBlock x:Name="TxtSub2A" Text="Fps+inputlag" FontSize="12" Foreground="#a1a1aa" HorizontalAlignment="Center" Margin="0,2,0,0"/>
                                                        <TextBlock x:Name="TxtStatus2A" Text="Successfully!" FontSize="11" FontWeight="Bold" Foreground="#e4e4e7" HorizontalAlignment="Center" Margin="0,2,0,0" Visibility="Collapsed"/>
                                                    </StackPanel>
                                                </Button>
                                                <Button x:Name="BtnCpu24" Style="{StaticResource SecondaryButton}" Height="75" Margin="6">
                                                    <StackPanel VerticalAlignment="Center">
                                                        <TextBlock x:Name="TxtTitle24" Text="0x24" FontSize="17" FontWeight="Bold" HorizontalAlignment="Center" Foreground="White"/>
                                                        <TextBlock x:Name="TxtSub24" Text="รีตัวไว เเนะนำ" FontSize="12" Foreground="#a1a1aa" HorizontalAlignment="Center" Margin="0,2,0,0"/>
                                                        <TextBlock x:Name="TxtStatus24" Text="Successfully!" FontSize="11" FontWeight="Bold" Foreground="#e4e4e7" HorizontalAlignment="Center" Margin="0,2,0,0" Visibility="Collapsed"/>
                                                    </StackPanel>
                                                </Button>
                                                <Button x:Name="BtnCpu18" Style="{StaticResource SecondaryButton}" Height="75" Margin="6">
                                                    <StackPanel VerticalAlignment="Center">
                                                        <TextBlock x:Name="TxtTitle18" Text="0x18" FontSize="17" FontWeight="Bold" HorizontalAlignment="Center" Foreground="White"/>
                                                        <TextBlock x:Name="TxtSub18" Text="Basic" FontSize="12" Foreground="#a1a1aa" HorizontalAlignment="Center" Margin="0,2,0,0"/>
                                                        <TextBlock x:Name="TxtStatus18" Text="Successfully!" FontSize="11" FontWeight="Bold" Foreground="#e4e4e7" HorizontalAlignment="Center" Margin="0,2,0,0" Visibility="Collapsed"/>
                                                    </StackPanel>
                                                </Button>
                                                <Button x:Name="BtnCpuDef" Style="{StaticResource SecondaryButton}" Height="75" Margin="6">
                                                    <StackPanel VerticalAlignment="Center">
                                                        <TextBlock x:Name="TxtTitleDef" Text="Default" FontSize="17" FontWeight="Bold" HorizontalAlignment="Center" Foreground="White"/>
                                                        <TextBlock x:Name="TxtSubDef" Text="ค่าเริ่มต้นของระบบ" FontSize="12" Foreground="#a1a1aa" HorizontalAlignment="Center" Margin="0,2,0,0"/>
                                                        <TextBlock x:Name="TxtStatusDef" Text="Successfully!" FontSize="11" FontWeight="Bold" Foreground="#e4e4e7" HorizontalAlignment="Center" Margin="0,2,0,0" Visibility="Collapsed"/>
                                                    </StackPanel>
                                                </Button>
                                            </UniformGrid>
                                        </StackPanel>
                                    </Border>
                                    <Border Background="{StaticResource CardGradient}" CornerRadius="12" Margin="0,0,0,20" Padding="30" BorderThickness="1" BorderBrush="#4a1217">
                                        <StackPanel>
                                            <StackPanel Orientation="Horizontal" Margin="0,0,0,20">
                                                <Rectangle Width="4" Height="18" Fill="{StaticResource AccentGradient}" Margin="0,0,12,0" RadiusX="2" RadiusY="2"/>
                                                <TextBlock Text="Gpedit For FiveM!!" Foreground="White" FontWeight="Bold" FontSize="16"/>
                                            </StackPanel>
                                            <TextBlock Text="เปลี่ยนภาพการเล่นFiveMให้เล่นภาพเล่นง่ายกว่าเดิมรีไว ปั้มไว" Foreground="#a1a1aa" Margin="0,0,0,20"/>
                                            <StackPanel Orientation="Horizontal">
                                                <Button x:Name="BtnUnpark" Style="{StaticResource PremiumButton}" Width="240" Height="55" Margin="0,0,15,0">
                                                    <StackPanel Orientation="Horizontal">
                                                        <TextBlock FontFamily="Segoe MDL2 Assets" Text="&#xE945;" FontSize="18" Margin="0,0,10,0" VerticalAlignment="Center"/>
                                                        <TextBlock Text="SetGpedit of Freedom" FontWeight="Bold" FontSize="14" VerticalAlignment="Center"/>
                                                    </StackPanel>
                                                </Button>
                                                <Button x:Name="BtnPark" Style="{StaticResource SecondaryButton}" Width="200" Height="55">
                                                    <StackPanel Orientation="Horizontal">
                                                        <TextBlock FontFamily="Segoe MDL2 Assets" Text="&#xE777;" FontSize="18" Margin="0,0,10,0" VerticalAlignment="Center" Foreground="#a1a1aa"/>
                                                        <TextBlock Text="Restore" FontWeight="Bold" FontSize="14" VerticalAlignment="Center" Foreground="#e4e4e7"/>
                                                    </StackPanel>
                                                </Button>
                                            </StackPanel>
                                        </StackPanel>
                                    </Border>
                                </StackPanel>
                            </ScrollViewer>
                        </Grid>

                        <!-- VIEW 3: INPUT -->
                        <Grid x:Name="ViewInput" Visibility="Collapsed">
                            <Grid.RowDefinitions>
                                <RowDefinition Height="Auto"/>
                                <RowDefinition Height="*"/>
                            </Grid.RowDefinitions>
                            <StackPanel Grid.Row="0" Margin="0,0,0,30">
                                <TextBlock Text="Input (Mouse/Keyboard)" Foreground="White" FontSize="30" FontWeight="Bold"/>
                                <TextBlock Text="ปิด Mouse Acceleration โดยไม่เปลี่ยนความไวเมาส์หรือคีย์บอร์ด" Foreground="#a1a1aa" FontSize="15" Margin="0,6,0,0"/>
                            </StackPanel>

                            <Border Grid.Row="1" Background="{StaticResource CardGradient}" CornerRadius="12" Padding="30" BorderThickness="1" BorderBrush="#4a1217" VerticalAlignment="Top">
                                <StackPanel>
                                    <StackPanel Orientation="Horizontal" Margin="0,0,0,20">
                                        <Rectangle Width="4" Height="18" Fill="{StaticResource AccentGradient}" Margin="0,0,12,0" RadiusX="2" RadiusY="2"/>
                                        <TextBlock Text="Mouse Fix &amp; Keyboard Response" Foreground="White" FontWeight="Bold" FontSize="16"/>
                                    </StackPanel>
                                    <TextBlock Text="ปิดการเร่งความเร็วเมาส์ของ Windows เท่านั้น ความรู้สึกการควบคุมขึ้นกับเกมและอุปกรณ์ และไม่รับประกันว่าจะลด input latency" Foreground="#a1a1aa" Margin="0,0,0,25" TextWrapping="Wrap"/>
                                    <Button x:Name="BtnInputMouse" Style="{StaticResource PremiumButton}" Height="55" Margin="0,0,0,15">
                                        <StackPanel Orientation="Horizontal">
                                            <TextBlock FontFamily="Segoe MDL2 Assets" Text="&#xE962;" FontSize="18" Margin="0,0,10,0" VerticalAlignment="Center"/>
                                            <TextBlock Text="DISABLE MOUSE ACCELERATION" FontWeight="Bold" FontSize="14" VerticalAlignment="Center"/>
                                        </StackPanel>
                                    </Button>
                                    <Button x:Name="BtnInputRestore" Style="{StaticResource SecondaryButton}" Height="50">
                                        <StackPanel Orientation="Horizontal">
                                            <TextBlock FontFamily="Segoe MDL2 Assets" Text="&#xE777;" FontSize="18" Margin="0,0,10,0" VerticalAlignment="Center" Foreground="#a1a1aa"/>
                                            <TextBlock Text="RESTORE PREVIOUS INPUT SETTINGS" FontWeight="Bold" FontSize="14" VerticalAlignment="Center" Foreground="#e4e4e7"/>
                                        </StackPanel>
                                    </Button>
                                </StackPanel>
                            </Border>
                        </Grid>

                        <!-- VIEW 4: NETWORK -->
                        <Grid x:Name="ViewNetwork" Visibility="Collapsed">
                            <Grid.RowDefinitions>
                                <RowDefinition Height="Auto"/>
                                <RowDefinition Height="*"/>
                            </Grid.RowDefinitions>
                            <StackPanel Grid.Row="0" Margin="0,0,0,30">
                                <TextBlock Text="Network" Foreground="White" FontSize="30" FontWeight="Bold"/>
                                <TextBlock Text="ตั้งค่า FiveM QoS/DSCP และตรวจสอบการเชื่อมต่อเครือข่าย" Foreground="#a1a1aa" FontSize="15" Margin="0,6,0,0"/>
                            </StackPanel>
                            
                            <Border Grid.Row="1" Background="{StaticResource CardGradient}" CornerRadius="12" Padding="30" BorderThickness="1" BorderBrush="#4a1217" VerticalAlignment="Top">
                                <StackPanel>
                                    <StackPanel Orientation="Horizontal" Margin="0,0,0,20">
                                        <Rectangle Width="4" Height="18" Fill="{StaticResource AccentGradient}" Margin="0,0,12,0" RadiusX="2" RadiusY="2"/>
                                        <TextBlock Text="Network guidance" Foreground="White" FontWeight="Bold" FontSize="16"/>
                                    </StackPanel>
                                    <TextBlock Text="ตั้งค่า FiveM QoS/DSCP 46 ที่ Windows และตรวจสอบ gateway/อินเทอร์เน็ตได้ ทั้งนี้ router หรือ ISP อาจไม่ส่งต่อ DSCP จึงไม่รับประกันว่าจะลด ping" Foreground="#a1a1aa" Margin="0,0,0,25" TextWrapping="Wrap"/>
                                    <Button x:Name="BtnNetCheck" Style="{StaticResource PremiumButton}" Height="55" Margin="0,0,0,15">
                                        <StackPanel Orientation="Horizontal">
                                            <TextBlock FontFamily="Segoe MDL2 Assets" Text="&#xE9D9;" FontSize="18" Margin="0,0,10,0" VerticalAlignment="Center"/>
                                            <TextBlock Text="CHECK NETWORK LATENCY" FontWeight="Bold" FontSize="14" VerticalAlignment="Center"/>
                                        </StackPanel>
                                    </Button>
                                    <Button x:Name="BtnNetTweak" Style="{StaticResource PremiumButton}" Height="55" Margin="0,0,0,15">
                                        <StackPanel Orientation="Horizontal">
                                            <TextBlock FontFamily="Segoe MDL2 Assets" Text="&#xE774;" FontSize="18" Margin="0,0,10,0" VerticalAlignment="Center"/>
                                            <TextBlock Text="APPLY FIVEM NETWORK QOS / DSCP" FontWeight="Bold" FontSize="14" VerticalAlignment="Center"/>
                                        </StackPanel>
                                    </Button>
                                    <Button x:Name="BtnNetFlush" Style="{StaticResource SecondaryButton}" Height="50" Margin="0,0,0,15">
                                        <StackPanel Orientation="Horizontal">
                                            <TextBlock FontFamily="Segoe MDL2 Assets" Text="&#xE81C;" FontSize="18" Margin="0,0,10,0" VerticalAlignment="Center" Foreground="#a1a1aa"/>
                                            <TextBlock Text="FLUSH DNS CACHE" FontWeight="Bold" FontSize="14" VerticalAlignment="Center" Foreground="#e4e4e7"/>
                                        </StackPanel>
                                    </Button>
                                    <Button x:Name="BtnNetRestore" Style="{StaticResource SecondaryButton}" Height="50">
                                        <StackPanel Orientation="Horizontal">
                                            <TextBlock FontFamily="Segoe MDL2 Assets" Text="&#xE777;" FontSize="18" Margin="0,0,10,0" VerticalAlignment="Center" Foreground="#a1a1aa"/>
                                            <TextBlock Text="RESTORE PREVIOUS QOS / DSCP" FontWeight="Bold" FontSize="14" VerticalAlignment="Center" Foreground="#e4e4e7"/>
                                        </StackPanel>
                                    </Button>
                                </StackPanel>
                            </Border>
                        </Grid>

                        <!-- VIEW 5: POWER / TIMER -->
                        <Grid x:Name="ViewPower" Visibility="Collapsed">
                            <Grid.RowDefinitions>
                                <RowDefinition Height="Auto"/>
                                <RowDefinition Height="*"/>
                            </Grid.RowDefinitions>
                            <StackPanel Grid.Row="0" Margin="0,0,0,30">
                                <TextBlock Text="Powerplan Freedom" Foreground="White" FontSize="30" FontWeight="Bold"/>
                                <TextBlock Text="Power Plan and Timer Resolution" Foreground="#a1a1aa" FontSize="15" Margin="0,6,0,0"/>
                            </StackPanel>
                            
                            <StackPanel Grid.Row="1">
                                <Border Background="{StaticResource CardGradient}" CornerRadius="12" Padding="30" BorderThickness="1" BorderBrush="#4a1217" Margin="0,0,0,20">
                                    <StackPanel>
                                        <StackPanel Orientation="Horizontal" Margin="0,0,0,20">
                                            <Rectangle Width="4" Height="18" Fill="{StaticResource AccentGradient}" Margin="0,0,12,0" RadiusX="2" RadiusY="2"/>
                                            <TextBlock Text="Power Plan Freedom" Foreground="White" FontWeight="Bold" FontSize="16"/>
                                        </StackPanel>
                                        <TextBlock Text="เพิ่ม PowerPlan Freedom เหมาะสำหรับเล่น FiveM" Foreground="#a1a1aa" Margin="0,0,0,20"/>
                                        <Button x:Name="BtnPowerImport" Style="{StaticResource PremiumButton}" Height="55">
                                            <StackPanel Orientation="Horizontal">
                                                <TextBlock FontFamily="Segoe MDL2 Assets" Text="&#xE898;" FontSize="18" Margin="0,0,10,0" VerticalAlignment="Center"/>
                                                <TextBlock Text="IMPORT &amp; APPLY POWER PLAN" FontWeight="Bold" FontSize="14" VerticalAlignment="Center"/>
                                            </StackPanel>
                                        </Button>
                                    </StackPanel>
                                </Border>
                                
                                <Border Background="{StaticResource CardGradient}" CornerRadius="12" Padding="30" BorderThickness="1" BorderBrush="#4a1217">
                                    <StackPanel>
                                        <StackPanel Orientation="Horizontal" Margin="0,0,0,20">
                                            <Rectangle Width="4" Height="18" Fill="{StaticResource AccentGradient}" Margin="0,0,12,0" RadiusX="2" RadiusY="2"/>
                                            <TextBlock Text="Timer Resolution" Foreground="White" FontWeight="Bold" FontSize="16"/>
                                        </StackPanel>
                                        <TextBlock Text="ขอ Timer Resolution สูงสุดที่ระบบรองรับเฉพาะขณะ FiveM ทำงาน (Windows อาจกำหนดผลจริงแตกต่างกัน)" Foreground="#a1a1aa" Margin="0,0,0,20"/>
                                        <StackPanel Orientation="Horizontal">
                                            <Button x:Name="BtnTimerEnable" Style="{StaticResource PremiumButton}" Width="240" Height="55" Margin="0,0,15,0">
                                                <StackPanel Orientation="Horizontal">
                                                    <TextBlock FontFamily="Segoe MDL2 Assets" Text="&#xE823;" FontSize="18" Margin="0,0,10,0" VerticalAlignment="Center"/>
                                                    <TextBlock Text="Enable for FiveM" FontWeight="Bold" FontSize="14" VerticalAlignment="Center"/>
                                                </StackPanel>
                                            </Button>
                                            <Button x:Name="BtnTimerDisable" Style="{StaticResource SecondaryButton}" Width="200" Height="55">
                                                <StackPanel Orientation="Horizontal">
                                                    <TextBlock FontFamily="Segoe MDL2 Assets" Text="&#xE777;" FontSize="18" Margin="0,0,10,0" VerticalAlignment="Center" Foreground="#a1a1aa"/>
                                                    <TextBlock Text="Disable Timer Service" FontWeight="Bold" FontSize="14" VerticalAlignment="Center" Foreground="#e4e4e7"/>
                                                </StackPanel>
                                            </Button>
                                        </StackPanel>
                                    </StackPanel>
                                </Border>
                            </StackPanel>
                        </Grid>

                        <!-- VIEW 6: CLEANER (TOOLS) -->
                        <Grid x:Name="ViewTools" Visibility="Collapsed">
                            <Grid.RowDefinitions>
                                <RowDefinition Height="Auto"/>
                                <RowDefinition Height="*"/>
                            </Grid.RowDefinitions>
                            <StackPanel Grid.Row="0" Margin="0,0,0,24">
                                <TextBlock Text="Cleaner" Foreground="White" FontSize="30" FontWeight="Bold"/>
                                <TextBlock Text="ล้างไฟล์ชั่วคราวและตรวจสอบ RAM โดยไม่บังคับล้างหน่วยความจำที่ Windows จัดการเอง" Foreground="#a1a1aa" FontSize="15" Margin="0,6,0,0"/>
                            </StackPanel>
                            
                            <StackPanel Grid.Row="1">
                                <!-- Card 1: RAM & System Junk -->
                                <Border Background="{StaticResource CardGradient}" CornerRadius="12" Padding="25" BorderThickness="1" BorderBrush="#4a1217" Margin="0,0,0,20">
                                    <StackPanel>
                                        <StackPanel Orientation="Horizontal" Margin="0,0,0,15">
                                            <Rectangle Width="4" Height="18" Fill="{StaticResource AccentGradient}" Margin="0,0,12,0" RadiusX="2" RadiusY="2"/>
                                            <TextBlock Text="System &amp; RAM Optimization" Foreground="White" FontWeight="Bold" FontSize="16"/>
                                        </StackPanel>
                                        <TextBlock Text="คืนหน่วยความจำ RAM และทำความสะอาดไฟล์ชั่วคราว ขยะสะสมของระบบ Windows" Foreground="#a1a1aa" Margin="0,0,0,18"/>
                                        
                                        <Grid>
                                            <Grid.ColumnDefinitions>
                                                <ColumnDefinition Width="*"/>
                                                <ColumnDefinition Width="*"/>
                                            </Grid.ColumnDefinitions>
                                            
                                            <!-- Button: Free RAM -->
                                            <Button x:Name="BtnFreeRam" Grid.Column="0" Style="{StaticResource PremiumButton}" Height="75" Margin="0,0,10,0">
                                                <StackPanel HorizontalAlignment="Center">
                                                    <StackPanel Orientation="Horizontal" HorizontalAlignment="Center" Margin="0,0,0,4">
                                                        <TextBlock FontFamily="Segoe MDL2 Assets" Text="&#xE9A1;" FontSize="20" Margin="0,0,8,0" VerticalAlignment="Center"/>
                                                        <TextBlock Text="CHECK AVAILABLE RAM" FontWeight="Bold" FontSize="14" VerticalAlignment="Center"/>
                                                    </StackPanel>
                                                    <TextBlock Text="ตรวจสอบ RAM ว่างโดยไม่ล้างแคชหรือ Working Set" FontSize="11" Foreground="#a1a1aa" HorizontalAlignment="Center"/>
                                                </StackPanel>
                                            </Button>
                                            
                                            <!-- Button: Deep Clean Junk -->
                                            <Button x:Name="BtnDeepClean" Grid.Column="1" Style="{StaticResource SecondaryButton}" Height="75" Margin="10,0,0,0">
                                                <StackPanel HorizontalAlignment="Center">
                                                    <StackPanel Orientation="Horizontal" HorizontalAlignment="Center" Margin="0,0,0,4">
                                                        <TextBlock FontFamily="Segoe MDL2 Assets" Text="&#xE74D;" FontSize="20" Foreground="#ff4d5e" Margin="0,0,8,0" VerticalAlignment="Center"/>
                                                        <TextBlock Text="DEEP CLEAN JUNK FILES" FontWeight="Bold" FontSize="14" Foreground="White" VerticalAlignment="Center"/>
                                                    </StackPanel>
                                                    <TextBlock Text="ล้าง Temp, รายงานข้อผิดพลาด และ Thumbnail cache (ไม่ลบถังขยะ)" FontSize="11" Foreground="#a1a1aa" HorizontalAlignment="Center"/>
                                                </StackPanel>
                                            </Button>
                                        </Grid>
                                    </StackPanel>
                                </Border>

                                <!-- Card 2: Gaming & Shader Cache -->
                                <Border Background="{StaticResource CardGradient}" CornerRadius="12" Padding="25" BorderThickness="1" BorderBrush="#4a1217">
                                    <StackPanel>
                                        <StackPanel Orientation="Horizontal" Margin="0,0,0,15">
                                            <Rectangle Width="4" Height="18" Fill="{StaticResource AccentGradient}" Margin="0,0,12,0" RadiusX="2" RadiusY="2"/>
                                            <TextBlock Text="Gaming &amp; Graphics Cache" Foreground="White" FontWeight="Bold" FontSize="16"/>
                                        </StackPanel>
                                        <TextBlock Text="ล้างแคชเพื่อแก้ปัญหาเฉพาะหน้าได้ แต่อาจทำให้เกมโหลดช้าหรือกระตุกชั่วคราวระหว่างสร้างแคชใหม่" Foreground="#a1a1aa" Margin="0,0,0,18"/>
                                        
                                        <Grid>
                                            <Grid.ColumnDefinitions>
                                                <ColumnDefinition Width="*"/>
                                                <ColumnDefinition Width="*"/>
                                            </Grid.ColumnDefinitions>
                                            
                                            <!-- Button: Clean FiveM Cache -->
                                            <Button x:Name="BtnFiveMCache" Grid.Column="0" Style="{StaticResource SecondaryButton}" Height="75" Margin="0,0,10,0">
                                                <StackPanel HorizontalAlignment="Center">
                                                    <StackPanel Orientation="Horizontal" HorizontalAlignment="Center" Margin="0,0,0,4">
                                                        <TextBlock FontFamily="Segoe MDL2 Assets" Text="&#xE7FC;" FontSize="20" Foreground="#ff4d5e" Margin="0,0,8,0" VerticalAlignment="Center"/>
                                                        <TextBlock Text="CLEAN FIVEM CACHE" FontWeight="Bold" FontSize="14" Foreground="White" VerticalAlignment="Center"/>
                                                    </StackPanel>
                                                    <TextBlock Text="ล้าง Cache, Server-Cache &amp; Priv-Cache ของ FiveM" FontSize="11" Foreground="#a1a1aa" HorizontalAlignment="Center"/>
                                                </StackPanel>
                                            </Button>
                                            
                                            <!-- Button: Optimize GPU Shaders -->
                                            <Button x:Name="BtnGpu" Grid.Column="1" Style="{StaticResource SecondaryButton}" Height="75" Margin="10,0,0,0">
                                                <StackPanel HorizontalAlignment="Center">
                                                    <StackPanel Orientation="Horizontal" HorizontalAlignment="Center" Margin="0,0,0,4">
                                                        <TextBlock FontFamily="Segoe MDL2 Assets" Text="&#xE945;" FontSize="20" Foreground="#ff4d5e" Margin="0,0,8,0" VerticalAlignment="Center"/>
                                                        <TextBlock Text="CLEAR GPU SHADERS" FontWeight="Bold" FontSize="14" Foreground="White" VerticalAlignment="Center"/>
                                                    </StackPanel>
                                                    <TextBlock Text="ลบแคชที่สร้างใหม่ได้ ไม่ได้เพิ่ม FPS โดยตรง" FontSize="11" Foreground="#a1a1aa" HorizontalAlignment="Center"/>
                                                </StackPanel>
                                            </Button>
                                        </Grid>
                                    </StackPanel>
                                </Border>
                            </StackPanel>
                        </Grid>

                        <!-- VIEW: BOOST -->
                        <Grid x:Name="ViewBoost" Visibility="Collapsed">
                            <Grid.RowDefinitions>
                                <RowDefinition Height="Auto"/>
                                <RowDefinition Height="*"/>
                            </Grid.RowDefinitions>
                            <StackPanel Grid.Row="0" Margin="0,0,0,24">
                                <TextBlock Text="Boost" Foreground="White" FontSize="30" FontWeight="Bold"/>
                                <TextBlock Text="เครื่องมือสำหรับตรวจสอบและปรับค่าที่รองรับ โดยไม่มีการรับประกัน FPS, latency หรือ ping" Foreground="#a1a1aa" FontSize="15" Margin="0,6,0,0"/>
                            </StackPanel>
                            
                            <StackPanel Grid.Row="1">
                                <!-- Card 1: Core System & Game Boost -->
                                <Border Background="{StaticResource CardGradient}" CornerRadius="12" Padding="25" BorderThickness="1" BorderBrush="#4a1217" Margin="0,0,0,20">
                                    <StackPanel>
                                        <StackPanel Orientation="Horizontal" Margin="0,0,0,15">
                                            <Rectangle Width="4" Height="18" Fill="{StaticResource AccentGradient}" Margin="0,0,12,0" RadiusX="2" RadiusY="2"/>
                                            <TextBlock Text="Freedom Ultra Game Boost" Foreground="White" FontWeight="Bold" FontSize="16"/>
                                        </StackPanel>
                                        <TextBlock Foreground="#a1a1aa" TextWrapping="Wrap" Margin="0,0,0,18" Text="เปิด Windows Game Mode และปิดการบันทึก Game DVR เพื่อลดงานบันทึกเบื้องหลัง การเปลี่ยนแปลงจะบันทึกค่าเดิมไว้ให้ Revert; ไม่รับประกัน FPS หรือ ping เพิ่มขึ้น"/>
                                        
                                        <Grid>
                                            <Grid.ColumnDefinitions>
                                                <ColumnDefinition Width="*"/>
                                                <ColumnDefinition Width="*"/>
                                            </Grid.ColumnDefinitions>
                                            <Button x:Name="BtnBoostApply" Grid.Column="0" Style="{StaticResource PremiumButton}" Height="60" Margin="0,0,10,0">
                                                <StackPanel Orientation="Horizontal">
                                                    <TextBlock FontFamily="Segoe MDL2 Assets" Text="&#xE945;" FontSize="20" Margin="0,0,10,0" VerticalAlignment="Center"/>
                                                    <TextBlock Text="APPLY BOOST" FontWeight="Bold" FontSize="14" VerticalAlignment="Center"/>
                                                </StackPanel>
                                            </Button>
                                            <Button x:Name="BtnBoostRevert" Grid.Column="1" Style="{StaticResource SecondaryButton}" Height="60" Margin="10,0,0,0">
                                                <StackPanel Orientation="Horizontal">
                                                    <TextBlock FontFamily="Segoe MDL2 Assets" Text="&#xE777;" FontSize="20" Foreground="#a1a1aa" Margin="0,0,10,0" VerticalAlignment="Center"/>
                                                    <TextBlock Text="REVERT BOOST" FontWeight="Bold" FontSize="14" Foreground="#e4e4e7" VerticalAlignment="Center"/>
                                                </StackPanel>
                                            </Button>
                                        </Grid>
                                    </StackPanel>
                                </Border>

                                <!-- Card 2: Background & Network Actions -->
                                <Border Background="{StaticResource CardGradient}" CornerRadius="12" Padding="25" BorderThickness="1" BorderBrush="#4a1217">
                                    <StackPanel>
                                        <StackPanel Orientation="Horizontal" Margin="0,0,0,15">
                                            <Rectangle Width="4" Height="18" Fill="{StaticResource AccentGradient}" Margin="0,0,12,0" RadiusX="2" RadiusY="2"/>
                                            <TextBlock Text="Background &amp; Network Quick Actions" Foreground="White" FontWeight="Bold" FontSize="16"/>
                                        </StackPanel>
                                        <TextBlock Text="ปิดโปรแกรม/เซอร์วิสพื้นหลังที่แอบกินทรัพยากร และล้างแคชเครือข่ายเพื่อลดอาการ Ping แกว่ง" Foreground="#a1a1aa" Margin="0,0,0,18"/>
                                        
                                        <Grid>
                                            <Grid.ColumnDefinitions>
                                                <ColumnDefinition Width="*"/>
                                                <ColumnDefinition Width="*"/>
                                            </Grid.ColumnDefinitions>
                                            <Button x:Name="BtnKillBg" Grid.Column="0" Style="{StaticResource SecondaryButton}" Height="60" Margin="0,0,10,0">
                                                <StackPanel Orientation="Horizontal">
                                                    <TextBlock FontFamily="Segoe MDL2 Assets" Text="&#xE711;" FontSize="20" Foreground="#ff4d5e" Margin="0,0,10,0" VerticalAlignment="Center"/>
                                                    <TextBlock Text="CLOSE BACKGROUND APPS" FontWeight="Bold" FontSize="13" Foreground="#e4e4e7" VerticalAlignment="Center"/>
                                                </StackPanel>
                                            </Button>
                                            <Button x:Name="BtnFlushNet" Grid.Column="1" Style="{StaticResource SecondaryButton}" Height="60" Margin="10,0,0,0">
                                                <StackPanel Orientation="Horizontal">
                                                    <TextBlock FontFamily="Segoe MDL2 Assets" Text="&#xE839;" FontSize="20" Foreground="#ff4d5e" Margin="0,0,10,0" VerticalAlignment="Center"/>
                                                    <TextBlock Text="FLUSH DNS / NET CACHE" FontWeight="Bold" FontSize="13" Foreground="#e4e4e7" VerticalAlignment="Center"/>
                                                </StackPanel>
                                            </Button>
                                        </Grid>
                                    </StackPanel>
                                </Border>
                            </StackPanel>
                        </Grid>

                        <!-- VIEW 7: RESTORE -->
                        <Grid x:Name="ViewRestore" Visibility="Collapsed">
                            <Grid.RowDefinitions>
                                <RowDefinition Height="Auto"/>
                                <RowDefinition Height="*"/>
                            </Grid.RowDefinitions>
                            <StackPanel Grid.Row="0" Margin="0,0,0,30">
                                <TextBlock Text="Restore (คืนค่าเดิม)" Foreground="White" FontSize="30" FontWeight="Bold"/>
                                <TextBlock Text="คืนค่าเฉพาะรายการที่โปรแกรมรองรับ ไม่สามารถย้อนคืนค่าของทุกโปรแกรมหรือค่าที่ไม่มี Snapshot ได้" Foreground="#a1a1aa" FontSize="15" Margin="0,6,0,0"/>
                            </StackPanel>
                            
                            <Border Grid.Row="1" Background="#190407" CornerRadius="12" Padding="30" BorderThickness="1" BorderBrush="#5e131d" VerticalAlignment="Top">
                                <StackPanel>
                                    <StackPanel Orientation="Horizontal" Margin="0,0,0,20">
                                        <Rectangle Width="4" Height="18" Fill="#ef4444" Margin="0,0,12,0" RadiusX="2" RadiusY="2"/>
                                        <TextBlock Text="System Restore &amp; Backup" Foreground="White" FontWeight="Bold" FontSize="16"/>
                                    </StackPanel>
                                    <TextBlock Text="คืนค่า Power Plan, Input/QoS, Game Mode, MMCSS/TCP และ Network Adapter ที่มี Snapshot พร้อมลบ Timer Service ของ Freedom" Foreground="#a1a1aa" Margin="0,0,0,25" TextWrapping="Wrap"/>
                                    <Button x:Name="BtnRestoreAll" Height="55" Margin="0,0,0,15">
                                        <Button.Style>
                                            <Style TargetType="Button" BasedOn="{StaticResource SecondaryButton}">
                                                <Setter Property="BorderBrush" Value="#4f152b"/>
                                                <Style.Triggers>
                                                    <Trigger Property="IsMouseOver" Value="True">
                                                        <Setter Property="Background" Value="#3d1121"/>
                                                    </Trigger>
                                                </Style.Triggers>
                                            </Style>
                                        </Button.Style>
                                        <StackPanel Orientation="Horizontal">
                                            <TextBlock FontFamily="Segoe MDL2 Assets" Text="&#xE72C;" FontSize="18" Margin="0,0,10,0" VerticalAlignment="Center" Foreground="#ff5a8e"/>
                                            <TextBlock Text="RESET SUPPORTED FREEDOM SETTINGS" FontWeight="Bold" FontSize="14" VerticalAlignment="Center" Foreground="#ff5a8e"/>
                                        </StackPanel>
                                    </Button>
                                    <Button x:Name="BtnRestorePoint" Style="{StaticResource SecondaryButton}" Height="50">
                                        <StackPanel Orientation="Horizontal">
                                            <TextBlock FontFamily="Segoe MDL2 Assets" Text="&#xE78C;" FontSize="18" Margin="0,0,10,0" VerticalAlignment="Center" Foreground="#a1a1aa"/>
                                            <TextBlock Text="CREATE SYSTEM RESTORE POINT" FontWeight="Bold" FontSize="14" VerticalAlignment="Center" Foreground="#e4e4e7"/>
                                        </StackPanel>
                                    </Button>
                                </StackPanel>
                            </Border>
                        </Grid>

                        <Grid x:Name="ViewAdvanced" Visibility="Collapsed">
                            <Grid.RowDefinitions>
                                <RowDefinition Height="Auto"/>
                                <RowDefinition Height="*"/>
                            </Grid.RowDefinitions>
                            <StackPanel Grid.Row="0" Margin="0,0,0,20">
                                <TextBlock Text="Advanced / Experimental" Foreground="White" FontSize="30" FontWeight="Bold"/>
                                                        <TextBlock Text="การตั้งค่านี้อาจทำให้ Windows หรืออุปกรณ์บูต/ทำงานผิดปกติ: Export BCD ก่อน, เปลี่ยนทีละค่า, รีสตาร์ต, ทดสอบฉาก/เซิร์ฟเวอร์เดิม 3 รอบ แล้วเทียบ frametime/FPS/ping กับ baseline; Restore หากแย่ลง" Foreground="#fca5a5" FontSize="14" Margin="0,6,0,0" TextWrapping="Wrap"/>
                            </StackPanel>
                            <ScrollViewer Grid.Row="1" VerticalScrollBarVisibility="Auto">
                                <StackPanel>
                                    <Border Background="#23070a" CornerRadius="12" Padding="22" BorderThickness="1" BorderBrush="#8b1b28" Margin="0,0,0,16">
                                        <StackPanel>
                                            <TextBlock Text="BCD Timer Stack" Foreground="White" FontWeight="Bold" FontSize="16" Margin="0,0,0,8"/>
                                            <TextBlock x:Name="TxtBcdStatus" Text="Current BCD values: not checked" Foreground="#d4d4d8" TextWrapping="Wrap" Margin="0,0,0,12"/>
                                            <CheckBox x:Name="ChkDeletePlatformClock" Content="Let Windows select the platform clock (delete forced useplatformclock)" Foreground="White" Margin="0,4"/>
                                            <CheckBox x:Name="ChkDynamicTick" Content="Set disabledynamictick = yes" Foreground="White" Margin="0,4"/>
                                            <CheckBox x:Name="ChkPlatformTick" Content="Optional: set useplatformtick = yes" Foreground="White" Margin="0,4"/>
                                            <CheckBox x:Name="ChkTscSyncEnhanced" Content="Optional: set tscsyncpolicy = Enhanced" Foreground="White" Margin="0,4"/>
                                            <WrapPanel Margin="0,12,0,0">
                                                <Button x:Name="BtnBcdApply" Style="{StaticResource PremiumButton}" Height="44" Padding="16,0" Margin="0,0,10,8">
                                                    <TextBlock Text="APPLY SELECTED BCD VALUES" FontWeight="Bold" VerticalAlignment="Center"/>
                                                </Button>
                                                <Button x:Name="BtnBcdExport" Style="{StaticResource SecondaryButton}" Height="44" Padding="16,0" Margin="0,0,10,8">
                                                    <TextBlock Text="EXPORT BCD BACKUP" FontWeight="Bold" VerticalAlignment="Center"/>
                                                </Button>
                                                <Button x:Name="BtnBcdRestore" Style="{StaticResource SecondaryButton}" Height="44" Padding="16,0" Margin="0,0,10,8">
                                                    <TextBlock Text="RESTORE BCD BACKUP" FontWeight="Bold" VerticalAlignment="Center"/>
                                                </Button>
                                            </WrapPanel>
                                        </StackPanel>
                                    </Border>
                                    <Border Background="{StaticResource CardGradient}" CornerRadius="12" Padding="22" BorderThickness="1" BorderBrush="#4a1217">
                                        <StackPanel>
                                            <TextBlock Text="MSI Mode (per-device)" Foreground="White" FontWeight="Bold" FontSize="16" Margin="0,0,0,8"/>
                                            <TextBlock Text="แสดงเฉพาะอุปกรณ์ที่มีค่า MSISupported อยู่แล้ว เลือกอุปกรณ์เองก่อนเปิดใช้; การรองรับใน Registry ไม่รับประกันความเข้ากันได้กับไดรเวอร์" Foreground="#fca5a5" TextWrapping="Wrap" Margin="0,0,0,12"/>
                                            <ListBox x:Name="LstMsiDevices" SelectionMode="Extended" Height="190" Background="#100609" Foreground="White" BorderBrush="#4a1217" DisplayMemberPath="Display"/>
                                            <WrapPanel Margin="0,12,0,0">
                                                <Button x:Name="BtnMsiRefresh" Style="{StaticResource SecondaryButton}" Height="44" Padding="16,0" Margin="0,0,10,8">
                                                    <TextBlock Text="SCAN SUPPORTED DEVICES" FontWeight="Bold" VerticalAlignment="Center"/>
                                                </Button>
                                                <Button x:Name="BtnMsiEnable" Style="{StaticResource PremiumButton}" Height="44" Padding="16,0" Margin="0,0,10,8">
                                                    <TextBlock Text="ENABLE MSI FOR SELECTED" FontWeight="Bold" VerticalAlignment="Center"/>
                                                </Button>
                                            </WrapPanel>
                                            <TextBlock x:Name="TxtMsiStatus" Text="Scan devices to inspect current MSI state." Foreground="#a1a1aa" TextWrapping="Wrap" Margin="0,6,0,0"/>
                                        </StackPanel>
                                    </Border>
                                </StackPanel>
                            </ScrollViewer>
                        </Grid>

                        <Grid x:Name="ViewSystem" Visibility="Collapsed">
                            <Grid.RowDefinitions>
                                <RowDefinition Height="Auto"/>
                                <RowDefinition Height="*"/>
                            </Grid.RowDefinitions>
                            <StackPanel Grid.Row="0" Margin="0,0,0,18">
                                <TextBlock Text="System / Input / Storage" Foreground="White" FontSize="30" FontWeight="Bold"/>
                                <TextBlock Text="สถานะและการตั้งค่าที่เลือกใช้ได้ โดยเก็บ Snapshot ก่อนเปลี่ยนค่า; ไม่รับประกัน FPS หรือ input lag ดีขึ้น" Foreground="#a1a1aa" FontSize="14" Margin="0,6,0,0" TextWrapping="Wrap"/>
                            </StackPanel>
                            <ScrollViewer Grid.Row="1" VerticalScrollBarVisibility="Auto">
                                <StackPanel>
                                    <Border Background="{StaticResource CardGradient}" CornerRadius="12" Padding="22" BorderThickness="1" BorderBrush="#4a1217" Margin="0,0,0,14">
                                        <StackPanel>
                                            <TextBlock Text="Input &amp; Pointer" Foreground="White" FontWeight="Bold" FontSize="16" Margin="0,0,0,8"/>
                                            <TextBlock x:Name="TxtInputStatus" Text="Input status: not checked" Foreground="#d4d4d8" TextWrapping="Wrap" Margin="0,0,0,12"/>
                                            <TextBlock Text="Mouse acceleration ปิดผ่าน MouseSpeed/Threshold และอัปเดตค่าที่ GUI ใช้ทันทีได้; ไม่เขียนทับ SmoothMouse curves เพราะไม่มี neutral curve สากลที่ปลอดภัย" Foreground="#a1a1aa" TextWrapping="Wrap" Margin="0,0,0,10"/>
                                            <WrapPanel>
                                                <Button x:Name="BtnInputApply" Style="{StaticResource PremiumButton}" Height="44" Padding="16,0" Margin="0,0,10,8">
                                                    <TextBlock Text="DISABLE POINTER PRECISION" FontWeight="Bold" VerticalAlignment="Center"/>
                                                </Button>
                                                <TextBlock Text="Queue size" Foreground="White" VerticalAlignment="Center" Margin="0,0,8,8"/>
                                                <ComboBox x:Name="CmbInputQueue" Width="90" Height="36" SelectedIndex="1" Margin="0,0,10,8">
                                                    <ComboBoxItem Content="20"/>
                                                    <ComboBoxItem Content="24"/>
                                                    <ComboBoxItem Content="32"/>
                                                </ComboBox>
                                                <Button x:Name="BtnInputQueueApply" Style="{StaticResource SecondaryButton}" Height="44" Padding="16,0" Margin="0,0,10,8">
                                                    <TextBlock Text="SET QUEUE (RESTART)" FontWeight="Bold" VerticalAlignment="Center"/>
                                                </Button>
                                            </WrapPanel>
                                            <TextBlock Text="Queue size มีผลกับ class driver และต้องรีสตาร์ต; ค่าเล็กอาจทำให้ input event สูญหาย ไม่ได้เพิ่ม polling rate ของเมาส์" Foreground="#fca5a5" TextWrapping="Wrap"/>
                                        </StackPanel>
                                    </Border>
                                    <Border Background="{StaticResource CardGradient}" CornerRadius="12" Padding="22" BorderThickness="1" BorderBrush="#4a1217" Margin="0,0,0,14">
                                        <StackPanel>
                                            <TextBlock Text="DWM / Desktop Effects" Foreground="White" FontWeight="Bold" FontSize="16" Margin="0,0,0,8"/>
                                            <WrapPanel Margin="0,0,0,8">
                                                <CheckBox x:Name="ChkTransparency" Content="Disable transparency" Foreground="White" IsChecked="True" Margin="0,4,16,4"/>
                                                <CheckBox x:Name="ChkAnimations" Content="Disable animations" Foreground="White" IsChecked="True" Margin="0,4,16,4"/>
                                                <CheckBox x:Name="ChkShadows" Content="Disable list shadows" Foreground="White" IsChecked="True" Margin="0,4,16,4"/>
                                                <CheckBox x:Name="ChkFullscreenOptimization" Content="Disable FiveM fullscreen optimizations" Foreground="White" Margin="0,4,16,4"/>
                                            </WrapPanel>
                                            <Button x:Name="BtnVisualApply" Style="{StaticResource PremiumButton}" Height="44" HorizontalAlignment="Left" Padding="16,0">
                                                <TextBlock Text="APPLY SELECTED VISUAL SETTINGS" FontWeight="Bold" VerticalAlignment="Center"/>
                                            </Button>
                                            <WrapPanel Margin="0,12,0,0">
                                                <CheckBox x:Name="ChkMpoDisable" Content="Experimental: Disable MPO (restart required)" Foreground="#fca5a5" Margin="0,4,12,4" ToolTip="May help diagnose flicker/stutter on some systems; can worsen performance or video playback. Backup is saved; change only for an A/B test."/>
                                                <Button x:Name="BtnMpoApply" Style="{StaticResource SecondaryButton}" Height="40" Padding="14,0" Margin="0,0,10,8">
                                                    <TextBlock Text="APPLY MPO TEST" FontWeight="Bold" VerticalAlignment="Center"/>
                                                </Button>
                                            </WrapPanel>
                                            <TextBlock x:Name="TxtDwmStatus" Text="DWM frame-latency registry tuning is intentionally omitted because no reliable universal setting is established." Foreground="#fca5a5" TextWrapping="Wrap" Margin="0,4,0,0"/>
                                        </StackPanel>
                                    </Border>
                                    <Border Background="{StaticResource CardGradient}" CornerRadius="12" Padding="22" BorderThickness="1" BorderBrush="#4a1217" Margin="0,0,0,14">
                                        <StackPanel>
                                            <TextBlock Text="Storage / Memory / Security / FiveM" Foreground="White" FontWeight="Bold" FontSize="16" Margin="0,0,0,8"/>
                                            <TextBlock x:Name="TxtSystemDiagnostics" Text="Select refresh to inspect storage, memory, security and FiveM configuration." Foreground="#d4d4d8" TextWrapping="Wrap" Margin="0,0,0,12"/>
                                            <WrapPanel>
                                                <Button x:Name="BtnSystemRefresh" Style="{StaticResource SecondaryButton}" Height="44" Padding="16,0" Margin="0,0,10,8">
                                                    <TextBlock Text="REFRESH DIAGNOSTICS" FontWeight="Bold" VerticalAlignment="Center"/>
                                                </Button>
                                                <Button x:Name="BtnFiveMConfigBackup" Style="{StaticResource SecondaryButton}" Height="44" Padding="16,0" Margin="0,0,10,8">
                                                    <TextBlock Text="BACKUP CITIZENFX.INI" FontWeight="Bold" VerticalAlignment="Center"/>
                                                </Button>
                                                <Button x:Name="BtnFiveMConfigRestore" Style="{StaticResource SecondaryButton}" Height="44" Padding="16,0" Margin="0,0,10,8">
                                                    <TextBlock Text="RESTORE CITIZENFX.INI" FontWeight="Bold" VerticalAlignment="Center"/>
                                                </Button>
                                                <Button x:Name="BtnMemoryCompression" Style="{StaticResource SecondaryButton}" Height="44" Padding="16,0" Margin="0,0,10,8">
                                                    <TextBlock Text="DISABLE MEMORY COMPRESSION (32GB+)" FontWeight="Bold" VerticalAlignment="Center"/>
                                                </Button>
                                            </WrapPanel>
                                            <TextBlock Text="Memory Compression change is opt-in and reversible from Boost → Revert. Not available below 32 GB RAM. Defender exclusions and real-time protection are not changed." Foreground="#fca5a5" TextWrapping="Wrap" Margin="0,4,0,0"/>
                                        </StackPanel>
                                    </Border>
                                    <Border Background="{StaticResource CardGradient}" CornerRadius="12" Padding="22" BorderThickness="1" BorderBrush="#4a1217" Margin="0,0,0,14">
                                        <StackPanel>
                                            <TextBlock Text="Startup Apps (read-only)" Foreground="White" FontWeight="Bold" FontSize="16" Margin="0,0,0,8"/>
                                            <TextBlock Text="รายการอ่านจาก Run keys และ Startup folders เท่านั้น; ไม่มีการปิดหรือ kill อัตโนมัติ" Foreground="#a1a1aa" TextWrapping="Wrap" Margin="0,0,0,10"/>
                                            <ListBox x:Name="LstStartupApps" Height="135" Background="#100609" Foreground="White" BorderBrush="#4a1217"/>
                                            <Button x:Name="BtnStartupRefresh" Style="{StaticResource SecondaryButton}" Height="42" HorizontalAlignment="Left" Padding="16,0" Margin="0,10,0,0">
                                                <TextBlock Text="REFRESH STARTUP LIST" FontWeight="Bold" VerticalAlignment="Center"/>
                                            </Button>
                                        </StackPanel>
                                    </Border>
                                    <Border Background="{StaticResource CardGradient}" CornerRadius="12" Padding="22" BorderThickness="1" BorderBrush="#4a1217" Margin="0,0,0,14">
                                        <StackPanel>
                                            <TextBlock Text="Scheduled Tasks / Background Features" Foreground="White" FontWeight="Bold" FontSize="16" Margin="0,0,0,8"/>
                                            <TextBlock Text="เลือกเฉพาะ task ที่ต้องการปิด; แต่ละ task จะบันทึกสถานะเดิมก่อนเปลี่ยน ไม่มีการ kill แอปหรือปิด service อัตโนมัติ" Foreground="#a1a1aa" TextWrapping="Wrap" Margin="0,0,0,10"/>
                                            <ListBox x:Name="LstOptionalTasks" SelectionMode="Extended" Height="140" Background="#100609" Foreground="White" BorderBrush="#4a1217"/>
                                            <WrapPanel Margin="0,10,0,0">
                                                <Button x:Name="BtnTasksRefresh" Style="{StaticResource SecondaryButton}" Height="42" Padding="16,0" Margin="0,0,10,8">
                                                    <TextBlock Text="SCAN TASKS" FontWeight="Bold" VerticalAlignment="Center"/>
                                                </Button>
                                                <Button x:Name="BtnTasksDisable" Style="{StaticResource PremiumButton}" Height="42" Padding="16,0" Margin="0,0,10,8">
                                                    <TextBlock Text="DISABLE SELECTED TASKS" FontWeight="Bold" VerticalAlignment="Center"/>
                                                </Button>
                                                <Button x:Name="BtnConsumerFeatures" Style="{StaticResource SecondaryButton}" Height="42" Padding="16,0" Margin="0,0,10,8">
                                                    <TextBlock Text="DISABLE TIPS / BACKGROUND APPS" FontWeight="Bold" VerticalAlignment="Center"/>
                                                </Button>
                                            </WrapPanel>
                                        </StackPanel>
                                    </Border>
                                    <Border Background="{StaticResource CardGradient}" CornerRadius="12" Padding="22" BorderThickness="1" BorderBrush="#4a1217" Margin="0,0,0,14">
                                        <StackPanel>
                                            <TextBlock Text="Network Profile / DNS" Foreground="White" FontWeight="Bold" FontSize="16" Margin="0,0,0,8"/>
                                            <TextBlock x:Name="TxtNetworkProfileStatus" Text="Network profile status: not checked" Foreground="#d4d4d8" TextWrapping="Wrap" Margin="0,0,0,10"/>
                                            <WrapPanel>
                                                <ComboBox x:Name="CmbNetworkProfile" Width="270" Height="38" Margin="0,0,10,8" DisplayMemberPath="Name"/>
                                                <ComboBox x:Name="CmbGamingDns" Width="190" Height="38" SelectedIndex="0" Margin="0,0,10,8">
                                                    <ComboBoxItem Content="No DNS change"/>
                                                    <ComboBoxItem Content="Cloudflare (1.1.1.1)"/>
                                                    <ComboBoxItem Content="Quad9 (9.9.9.9)"/>
                                                </ComboBox>
                                                <Button x:Name="BtnNetworkProfilePrivate" Style="{StaticResource SecondaryButton}" Height="42" Padding="16,0" Margin="0,0,10,8">
                                                    <TextBlock Text="SET SELECTED HOME PROFILE PRIVATE" FontWeight="Bold" VerticalAlignment="Center"/>
                                                </Button>
                                            </WrapPanel>
                                            <TextBlock Text="DNS dropdown เป็นคำแนะนำเท่านั้น ไม่มีการตั้ง DNS อัตโนมัติ; Private ใช้เฉพาะเครือข่ายบ้านที่เชื่อถือได้" Foreground="#a1a1aa" TextWrapping="Wrap"/>
                                        </StackPanel>
                                    </Border>
                                </StackPanel>
                            </ScrollViewer>
                        </Grid>
                    </Grid>
                </Grid>
            </Grid>
        </Grid>
    </Border>
</Window>
"@

# Read XAML
$reader = (New-Object System.Xml.XmlNodeReader $xaml)
$window = [Windows.Markup.XamlReader]::Load($reader)

function Show-FreedomNotice {
    param(
        [Parameter(Mandatory = $true)][string]$Title,
        [Parameter(Mandatory = $true)][string]$Message,
        [string]$Summary = "",
        [string]$Details = "",
        [ValidateSet("Success", "Warning", "Error")][string]$Kind = "Success"
    )

    $noticeXaml = @'
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Freedom Optimizer"
        Width="520" MinHeight="280" MaxHeight="560" SizeToContent="Height"
        WindowStyle="None" AllowsTransparency="True" Background="Transparent"
        ResizeMode="NoResize" ShowInTaskbar="False" WindowStartupLocation="CenterOwner">
    <Border Background="#0B0809" BorderBrush="#9F1724" BorderThickness="1" CornerRadius="16">
        <Border.Effect>
            <DropShadowEffect BlurRadius="28" ShadowDepth="0" Opacity="0.6" Color="#E11D2E"/>
        </Border.Effect>
        <Grid>
            <Grid.RowDefinitions>
                <RowDefinition Height="58"/>
                <RowDefinition Height="Auto"/>
                <RowDefinition Height="Auto"/>
                <RowDefinition Height="Auto"/>
            </Grid.RowDefinitions>
            <Border x:Name="NoticeHeader" Grid.Row="0" Background="#120A0C" CornerRadius="16,16,0,0">
                <Grid Margin="20,0">
                    <StackPanel Orientation="Horizontal" VerticalAlignment="Center">
                        <Border x:Name="StatusBadge" Width="9" Height="9" Background="#22C55E" CornerRadius="5" Margin="0,0,10,0"/>
                        <TextBlock Text="FREEDOM OPTIMIZER" Foreground="#A1A1AA" FontSize="11" FontWeight="Bold" VerticalAlignment="Center"/>
                    </StackPanel>
                    <Button x:Name="CloseButton" Content="×" Width="32" Height="32" HorizontalAlignment="Right"
                            Background="Transparent" Foreground="#A1A1AA" BorderThickness="0" FontSize="21" Cursor="Hand"/>
                </Grid>
            </Border>
            <StackPanel Grid.Row="1" Margin="24,22,24,14">
                <TextBlock x:Name="NoticeTitle" Text="Complete" Foreground="White" FontSize="22" FontWeight="Bold" TextWrapping="Wrap"/>
                <TextBlock x:Name="NoticeMessage" Text="" Foreground="#D4D4D8" FontSize="14" Margin="0,9,0,0" TextWrapping="Wrap"/>
                <Border x:Name="SummaryCard" Background="#160C0E" BorderBrush="#3F171D" BorderThickness="1" CornerRadius="10" Padding="14" Margin="0,17,0,0">
                    <TextBlock x:Name="NoticeSummary" Foreground="#F4F4F5" FontSize="13" TextWrapping="Wrap"/>
                </Border>
                <Button x:Name="DetailsButton" Content="ดูรายละเอียดเพิ่มเติม  +"
                        Background="Transparent" Foreground="#F87171" BorderThickness="0"
                        HorizontalAlignment="Left" Padding="0,12,8,4" FontSize="12" Cursor="Hand"/>
                <Border x:Name="DetailsPanel" Visibility="Collapsed" Background="#080607" BorderBrush="#321217"
                        BorderThickness="1" CornerRadius="8" Padding="10" Margin="0,6,0,0">
                    <ScrollViewer MaxHeight="155" VerticalScrollBarVisibility="Auto">
                        <TextBox x:Name="DetailsText" IsReadOnly="True" TextWrapping="Wrap"
                                 Background="Transparent" Foreground="#B8B8BE" BorderThickness="0"
                                 FontFamily="Consolas" FontSize="11" IsReadOnlyCaretVisible="True"/>
                    </ScrollViewer>
                </Border>
            </StackPanel>
            <Border Grid.Row="2" Height="1" Background="#281216" Margin="24,0"/>
            <Button x:Name="DoneButton" Grid.Row="3" Content="ตกลง" Width="110" Height="38"
                    HorizontalAlignment="Right" Margin="0,15,24,20"
                    Background="#C9152A" Foreground="White" BorderThickness="0" FontWeight="Bold"
                    Cursor="Hand">
                <Button.Template>
                    <ControlTemplate TargetType="Button">
                        <Border Background="{TemplateBinding Background}" CornerRadius="8">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                    </ControlTemplate>
                </Button.Template>
            </Button>
        </Grid>
    </Border>
</Window>
'@
    try {
        [xml]$noticeDocument = $noticeXaml
        $noticeReader = New-Object System.Xml.XmlNodeReader $noticeDocument
        $noticeWindow = [Windows.Markup.XamlReader]::Load($noticeReader)
        $noticeWindow.Owner = $window
        $noticeWindow.FindName("NoticeTitle").Text = $Title
        $noticeWindow.FindName("NoticeMessage").Text = $Message
        $noticeWindow.FindName("NoticeSummary").Text = $Summary
        $noticeWindow.FindName("DetailsText").Text = $Details

        $badge = $noticeWindow.FindName("StatusBadge")
        switch ($Kind) {
            "Warning" { $badge.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#F59E0B") }
            "Error" { $badge.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#EF4444") }
            default { $badge.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#22C55E") }
        }

        $detailsButton = $noticeWindow.FindName("DetailsButton")
        $detailsPanel = $noticeWindow.FindName("DetailsPanel")
        if ([string]::IsNullOrWhiteSpace($Details)) {
            $detailsButton.Visibility = "Collapsed"
        } else {
            $detailsButton.Add_Click({
                if ($detailsPanel.Visibility -eq [System.Windows.Visibility]::Collapsed) {
                    $detailsPanel.Visibility = [System.Windows.Visibility]::Visible
                    $detailsButton.Content = "ซ่อนรายละเอียด  −"
                } else {
                    $detailsPanel.Visibility = [System.Windows.Visibility]::Collapsed
                    $detailsButton.Content = "ดูรายละเอียดเพิ่มเติม  +"
                }
            })
        }
        $noticeWindow.FindName("CloseButton").Add_Click({ $noticeWindow.Close() })
        $noticeWindow.FindName("DoneButton").Add_Click({ $noticeWindow.Close() })
        $noticeWindow.FindName("NoticeHeader").Add_MouseLeftButtonDown({ $noticeWindow.DragMove() })
        [void]$noticeWindow.ShowDialog()
    } catch {
        throw "เปิดหน้าต่างแจ้งผลไม่สำเร็จ: $($_.Exception.Message)"
    }
}

# Define Arrays for easier looping
$views = @("ViewDashboard", "ViewCPU", "ViewInput", "ViewNetwork", "ViewPower", "ViewTools", "ViewBoost", "ViewRestore")
$navButtons = @("BtnNavDashboard", "BtnNavCPU", "BtnNavInput", "BtnNavNetwork", "BtnNavPower", "BtnNavTools", "BtnNavBoost", "BtnNavRestore")

# LOG FUNCTION
function Write-Log {
    param([string]$Message)
    # Log removed
}

# SYSTEM INFO GATHERING
function Update-SystemInfo {
    Write-Log "Gathering System Info..."
    try {
        $os = (Get-WmiObject Win32_OperatingSystem).Caption
        $window.FindName("SysOs").Text = "OS: $os"
        
        $cpu = (Get-WmiObject Win32_Processor).Name
        $window.FindName("SysCpu").Text = "CPU: $cpu"
        
        $ramObj = Get-WmiObject Win32_ComputerSystem
        $ramGb = [math]::Round($ramObj.TotalPhysicalMemory / 1GB, 1)
        $window.FindName("SysRam").Text = "RAM: $ramGb GB"
        
        # Simple HWID simulation or real UUID
        $uuid = (Get-WmiObject Win32_ComputerSystemProduct).UUID
        $window.FindName("SysHwid").Text = "HWID: $uuid"
        
        Write-Log "System Info updated."
    } catch {
        Write-Log "Failed to get system info."
    }
}

function Update-PrioButtons {
    param([int]$activeVal)
    $cpuBtns = @(
        @{ Name="BtnCpu26"; Status="TxtStatus26"; Sub="TxtSub26"; Val=38 },
        @{ Name="BtnCpu28"; Status="TxtStatus28"; Sub="TxtSub28"; Val=40 },
        @{ Name="BtnCpu2A"; Status="TxtStatus2A"; Sub="TxtSub2A"; Val=42 },
        @{ Name="BtnCpu24"; Status="TxtStatus24"; Sub="TxtSub24"; Val=36 },
        @{ Name="BtnCpu18"; Status="TxtStatus18"; Sub="TxtSub18"; Val=24 },
        @{ Name="BtnCpuDef"; Status="TxtStatusDef"; Sub="TxtSubDef"; Val=2 }
    )
    foreach ($item in $cpuBtns) {
        $btn = $window.FindName($item.Name)
        $st = $window.FindName($item.Status)
        $sub = $window.FindName($item.Sub)
        if ($item.Val -eq $activeVal) {
            if ($btn) { $btn.Style = $window.Resources["PremiumButton"] }
            if ($st) { $st.Visibility = "Visible" }
            if ($sub) { $sub.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#93c5fd") }
        } else {
            if ($btn) { $btn.Style = $window.Resources["SecondaryButton"] }
            if ($st) { $st.Visibility = "Collapsed" }
            if ($sub) { $sub.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#a1a1aa") }
        }
    }
}

function Update-Status {
    Write-Log "Refreshing Status..."
    try {
        # 1. Win32PrioritySeparation
        $win32prio = (Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl" -Name "Win32PrioritySeparation" -ErrorAction SilentlyContinue).Win32PrioritySeparation
        if ($null -ne $win32prio) {
            $hex = '0x{0:X2}' -f $win32prio
            $window.FindName("StatusPriority").Text = "Win32PrioritySeparation: $hex"
            Update-PrioButtons $win32prio
        }

        # 2. QoS FiveM Status
        $qosPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\QoS\FiveM.exe"
        $statusQosTxt = $window.FindName("StatusQos")
        if ($statusQosTxt) {
            if (Test-Path $qosPath) {
                    $statusQosTxt.Text = "QoS policy: Configured (may be ignored)"
                $statusQosTxt.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#e4e4e7")
            } else {
                $statusQosTxt.Text = "QoS FiveM: OFF"
                $statusQosTxt.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#a1a1aa")
            }
        }

        # 3. Timer Service Status
        $timerSvc = Get-Service -Name "STR" -ErrorAction SilentlyContinue
        $statusTimerTxt = $window.FindName("StatusTimer")
        if ($statusTimerTxt) {
            if ($null -ne $timerSvc -and $timerSvc.Status -eq 'Running') {
                $statusTimerTxt.Text = "Timer Service: Running (FiveM only)"
                $statusTimerTxt.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#e4e4e7")
            } else {
                $statusTimerTxt.Text = "Timer Service: Not running"
                $statusTimerTxt.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#a1a1aa")
            }
        }

        # 4. Active Power Plan Status
        $activeScheme = powercfg /getactivescheme 2>&1
        $statusPlanTxt = $window.FindName("StatusPlan")
        if ($statusPlanTxt -and $activeScheme -match '\((.*)\)') {
            $planName = $matches[1].Trim()
            $statusPlanTxt.Text = "Power Plan: $planName"
            if ($planName -like "*Freedom*") {
                $statusPlanTxt.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#e4e4e7")
            } else {
                $statusPlanTxt.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#a1a1aa")
            }
        }
    } catch {}
}

# STARTUP
Write-Log "Freedom ready  |  Administrator"
Update-SystemInfo
Update-Status

# Function to switch views
function Switch-View {
    param([string]$targetViewName, [string]$targetButtonName)
    foreach ($viewName in $views) {
        $window.FindName($viewName).Visibility = 'Collapsed'
    }
    $window.FindName($targetViewName).Visibility = 'Visible'
    foreach ($btnName in $navButtons) {
        $window.FindName($btnName).Style = $window.Resources["MenuButton"]
    }
    $window.FindName($targetButtonName).Style = $window.Resources["ActiveMenuButton"]
    Write-Log "Navigated to $targetViewName"
}

# NAVIGATION
$window.FindName("BtnNavDashboard").Add_Click({ Switch-View "ViewDashboard" "BtnNavDashboard" })
$window.FindName("BtnNavCPU").Add_Click({ Switch-View "ViewCPU" "BtnNavCPU" })
$window.FindName("BtnNavInput").Add_Click({ Switch-View "ViewInput" "BtnNavInput" })
$window.FindName("BtnNavNetwork").Add_Click({ Switch-View "ViewNetwork" "BtnNavNetwork" })
$window.FindName("BtnNavPower").Add_Click({ Switch-View "ViewPower" "BtnNavPower" })
$window.FindName("BtnNavTools").Add_Click({ Switch-View "ViewTools" "BtnNavTools" })
$window.FindName("BtnNavBoost").Add_Click({ Switch-View "ViewBoost" "BtnNavBoost" })
$window.FindName("BtnNavRestore").Add_Click({ Switch-View "ViewRestore" "BtnNavRestore" })

# DASHBOARD ACTIONS
$window.FindName("BtnRefreshStatus").Add_Click({ Update-Status })
$window.FindName("BtnApplyRec").Add_Click({
    $confirm = [FreedomThemedMessageBox]::Show("Apply All จะตั้งค่า Game Mode, input, visual effects, QoS/DSCP, MMCSS/TCP, active network adapter และ Power Plan สำหรับเกม การตั้งค่า driver อาจเพิ่มภาระ CPU/พลังงาน และไม่ได้รับประกัน FPS หรือ ping ดีขึ้น`n`nต้องการดำเนินการต่อหรือไม่?", "Freedom Optimizer - Apply All", [System.Windows.MessageBoxButton]::YesNo, [System.Windows.MessageBoxImage]::Warning)
    if ($confirm -ne [System.Windows.MessageBoxResult]::Yes) { return }
    $window.Cursor = [System.Windows.Input.Cursors]::Wait
    try {
    Write-Log "Applying Windows Game Mode, Game DVR, FiveM QoS/DSCP, and FiveM-only timer service without changing Win32 priority..."

    try {
        Set-FiveMQoS -ShowPopup:$false
    } catch {
        Show-FreedomNotice -Title "Apply ได้บางส่วน" -Message "ตั้งค่า FiveM QoS/DSCP ไม่สำเร็จ" -Summary $_.Exception.Message -Kind Error
        return
    }

    try {
        Set-FreedomGameModeSettings
    } catch {
        Show-FreedomNotice -Title "Apply ได้บางส่วน" -Message "ตั้งค่า FiveM QoS/DSCP แล้ว แต่ตั้งค่า Game Mode/Game DVR ไม่สำเร็จ" -Summary $_.Exception.Message -Kind Error
        return
    }

    try {
        Set-FreedomVisualSettings
        Set-FreedomPointerPrecision
    } catch {
        Show-FreedomNotice -Title "Apply ได้บางส่วน" -Message "ตั้งค่า Game Mode แล้ว แต่ปรับ visual effects หรือ pointer precision ไม่สำเร็จ" -Summary $_.Exception.Message -Kind Error
        return
    }

    try {
        Set-FreedomCoreSettings
    } catch {
        Show-FreedomNotice -Title "Apply ได้บางส่วน" -Message "ตั้งค่า Game Mode และ QoS/DSCP แล้ว แต่ชุด Responsiveness/Network ทำงานไม่ครบ" -Summary $_.Exception.Message -Kind Error
        return
    }

    try {
        Set-FreedomPowerPlanTuning
    } catch {
        Show-FreedomNotice -Title "Apply ได้บางส่วน" -Message "ตั้งค่า Responsiveness/Network แล้ว แต่ Power Plan tuning ไม่สำเร็จ" -Summary $_.Exception.Message -Kind Error
        return
    }

    # 4. Set Timer Resolution Service (STR) Installation
    Write-Log "Installing Set Timer Resolution Service..."
    $csCode = @'
using System;
using System.Runtime.InteropServices;
using System.ServiceProcess;
using System.ComponentModel;
using System.Configuration.Install;
using System.Collections.Generic;
using System.Reflection;
using System.IO;
using System.Management;
using System.Threading;
using System.Diagnostics;
[assembly: AssemblyVersion("2.1")]
[assembly: AssemblyProduct("Set Timer Resolution service")]
namespace WindowsService
{
    class WindowsService : ServiceBase
    {
        public WindowsService()
        {
            this.ServiceName = "STR";
            this.EventLog.Log = "Application";
            this.CanStop = true;
            this.CanHandlePowerEvent = false;
            this.CanHandleSessionChangeEvent = false;
            this.CanPauseAndContinue = false;
            this.CanShutdown = false;
        }
        static void Main()
        {
            ServiceBase.Run(new WindowsService());
        }
        protected override void OnStart(string[] args)
        {
            base.OnStart(args);
            ReadProcessList();
            NtQueryTimerResolution(out this.MininumResolution, out this.MaximumResolution, out this.DefaultResolution);
            if(null != this.EventLog)
                try { this.EventLog.WriteEntry(String.Format("Minimum={0}; Maximum={1}; Default={2}; Processes='{3}'", this.MininumResolution, this.MaximumResolution, this.DefaultResolution, null != this.ProcessesNames ? String.Join("','", this.ProcessesNames) : "")); }
                catch {}
            if(null == this.ProcessesNames)
            {
                SetMaximumResolution();
                return;
            }
            if(0 == this.ProcessesNames.Count)
            {
                return;
            }
            this.ProcessStartDelegate = new OnProcessStart(this.ProcessStarted);
            try
            {
                String query = String.Format("SELECT * FROM __InstanceCreationEvent WITHIN 0.5 WHERE (TargetInstance isa \"Win32_Process\") AND ((TargetInstance.Name=\"{0}\") OR (TargetInstance.Name LIKE \"FiveM_b%_GTAProcess.exe\"))", String.Join("\" OR TargetInstance.Name=\"", this.ProcessesNames));
                this.startWatch = new ManagementEventWatcher(query);
                this.startWatch.EventArrived += this.startWatch_EventArrived;
                this.startWatch.Start();
                foreach(Process process in Process.GetProcesses())
                {
                    if(IsTargetProcess(process.ProcessName))
                        this.ProcessStartDelegate.BeginInvoke((UInt32)process.Id, null, null);
                }
            }
            catch(Exception ee)
            {
                if(null != this.EventLog)
                    try { this.EventLog.WriteEntry(ee.ToString(), EventLogEntryType.Error); }
                    catch {}
            }
        }
        protected override void OnStop()
        {
            if(null != this.startWatch)
            {
                this.startWatch.Stop();
            }

            base.OnStop();
        }
        ManagementEventWatcher startWatch;
        void startWatch_EventArrived(object sender, EventArrivedEventArgs e) 
        {
            try
            {
                ManagementBaseObject process = (ManagementBaseObject)e.NewEvent.Properties["TargetInstance"].Value;
                UInt32 processId = (UInt32)process.Properties["ProcessId"].Value;
                this.ProcessStartDelegate.BeginInvoke(processId, null, null);
            } 
            catch(Exception ee) 
            {
                if(null != this.EventLog)
                    try { this.EventLog.WriteEntry(ee.ToString(), EventLogEntryType.Warning); }
                    catch {}

            }
        }
        [DllImport("kernel32.dll", SetLastError=true)]
        static extern Int32 WaitForSingleObject(IntPtr Handle, Int32 Milliseconds);
        [DllImport("kernel32.dll", SetLastError=true)]
        static extern IntPtr OpenProcess(UInt32 DesiredAccess, Int32 InheritHandle, UInt32 ProcessId);
        [DllImport("kernel32.dll", SetLastError=true)]
        static extern Int32 CloseHandle(IntPtr Handle);
        const UInt32 SYNCHRONIZE = 0x00100000;
        delegate void OnProcessStart(UInt32 processId);
        OnProcessStart ProcessStartDelegate = null;
        bool IsTargetProcess(String processName)
        {
            String name = processName.ToLowerInvariant() + ".exe";
            return this.ProcessesNames.Contains(name) ||
                (name.StartsWith("fivem_b", StringComparison.Ordinal) && name.EndsWith("_gtaprocess.exe", StringComparison.Ordinal));
        }
        void ProcessStarted(UInt32 processId)
        {
            SetMaximumResolution();
            IntPtr processHandle = IntPtr.Zero;
            try
            {
                processHandle = OpenProcess(SYNCHRONIZE, 0, processId);
                if(processHandle != IntPtr.Zero)
                    WaitForSingleObject(processHandle, -1);
            } 
            catch(Exception ee) 
            {
                if(null != this.EventLog)
                    try { this.EventLog.WriteEntry(ee.ToString(), EventLogEntryType.Warning); }
                    catch {}
            }
            finally
            {
                if(processHandle != IntPtr.Zero)
                    CloseHandle(processHandle); 
            }
            SetDefaultResolution();
        }
        List<String> ProcessesNames = null;
        void ReadProcessList()
        {
            String iniFilePath = Assembly.GetExecutingAssembly().Location + ".ini";
            if(File.Exists(iniFilePath))
            {
                this.ProcessesNames = new List<String>();
                String[] iniFileLines = File.ReadAllLines(iniFilePath);
                foreach(var line in iniFileLines)
                {
                    String[] names = line.Split(new char[] {',', ' ', ';'} , StringSplitOptions.RemoveEmptyEntries);
                    foreach(var name in names)
                    {
                        String lwr_name = name.ToLower();
                        if(!lwr_name.EndsWith(".exe"))
                            lwr_name += ".exe";
                        if(!this.ProcessesNames.Contains(lwr_name))
                            this.ProcessesNames.Add(lwr_name);
                    }
                }
            }
        }
        [DllImport("ntdll.dll", SetLastError=true)]
        static extern int NtSetTimerResolution(uint DesiredResolution, bool SetResolution, out uint CurrentResolution);
        [DllImport("ntdll.dll", SetLastError=true)]
        static extern int NtQueryTimerResolution(out uint MinimumResolution, out uint MaximumResolution, out uint ActualResolution);
        uint DefaultResolution = 0;
        uint MininumResolution = 0;
        uint MaximumResolution = 0;
        long processCounter = 0;
        void SetMaximumResolution()
        {
            long counter = Interlocked.Increment(ref this.processCounter);
            if(counter <= 1)
            {
                uint actual = 0;
                NtSetTimerResolution(this.MininumResolution, true, out actual);
                if(null != this.EventLog)
                    try { this.EventLog.WriteEntry(String.Format("Actual resolution = {0}", actual)); }
                    catch {}
            }
        }
        void SetDefaultResolution()
        {
            long counter = Interlocked.Decrement(ref this.processCounter);
            if(counter == 0)
            {
                uint actual = 0;
                NtSetTimerResolution(this.MininumResolution, false, out actual);
                if(null != this.EventLog)
                    try { this.EventLog.WriteEntry(String.Format("Actual resolution = {0}", actual)); }
                    catch {}
            }
        }
    }
    [RunInstaller(true)]
    public class WindowsServiceInstaller : Installer
    {
        public WindowsServiceInstaller()
        {
            ServiceProcessInstaller serviceProcessInstaller = new ServiceProcessInstaller();
            ServiceInstaller serviceInstaller = new ServiceInstaller();
            serviceProcessInstaller.Account = ServiceAccount.LocalSystem;
            serviceProcessInstaller.Username = null;
            serviceProcessInstaller.Password = null;
            serviceInstaller.DisplayName = "Set Timer Resolution Service";
            serviceInstaller.StartType = ServiceStartMode.Automatic;
            serviceInstaller.ServiceName = "STR";
            this.Installers.Add(serviceProcessInstaller);
            this.Installers.Add(serviceInstaller);
        }
    }
}
'@
    $csPath = "C:\Windows\SetTimerResolutionService.cs"
    $exePath = "C:\Windows\SetTimerResolutionService.exe"
    $legacyService = Get-Service -Name "Set Timer Resolution Service" -ErrorAction SilentlyContinue
    if ($legacyService) {
        Stop-Service -Name "Set Timer Resolution Service" -Force -ErrorAction SilentlyContinue
        sc.exe delete "Set Timer Resolution Service" | Out-Null
        Start-Sleep -Milliseconds 500
    }
    if (Get-Service -Name "STR" -ErrorAction SilentlyContinue) {
        Stop-Service -Name "STR" -Force -ErrorAction Stop
        sc.exe delete "STR" | Out-Null
        Start-Sleep -Milliseconds 800
    }
    [System.IO.File]::WriteAllText("$exePath.ini", "FiveM.exe,FiveM_GTAProcess.exe,FiveM_b3258_GTAProcess.exe")
    [System.IO.File]::WriteAllText($csPath, $csCode)
    $compiler = Join-Path $env:WINDIR "Microsoft.NET\Framework64\v4.0.30319\csc.exe"
    if (-not (Test-Path -LiteralPath $compiler)) { $compiler = Join-Path $env:WINDIR "Microsoft.NET\Framework\v4.0.30319\csc.exe" }
    if (-not (Test-Path -LiteralPath $compiler)) { throw "ไม่พบ C# compiler สำหรับติดตั้ง Timer Service" }
    $compile = Start-Process -FilePath $compiler -ArgumentList @("/nologo", "-r:System.ServiceProcess.dll", "-r:System.Configuration.Install.dll", "-r:System.Management.dll", "-out:$exePath", $csPath) -Wait -PassThru -WindowStyle Hidden
    if ($compile.ExitCode -ne 0) { throw "คอมไพล์ Timer Service ไม่สำเร็จ (exit code $($compile.ExitCode))" }
    Remove-Item -Path $csPath -ErrorAction SilentlyContinue | Out-Null
    New-Service -Name "STR" -DisplayName "Set Timer Resolution Service" -BinaryPathName "$exePath" -ErrorAction Stop | Out-Null
    Set-Service -Name "STR" -StartupType Automatic -ErrorAction Stop
    Set-Service -Name "STR" -Status Running -ErrorAction Stop

    $svcChk = Get-Service -Name "STR" -ErrorAction SilentlyContinue
    if ($null -eq $svcChk -or $svcChk.Status -ne 'Running') {
        Update-Status
        Show-FreedomNotice -Title "Apply ได้บางส่วน" -Message "ตั้งค่า QoS/DSCP และ Game Mode แล้ว แต่ Timer Service ยังไม่ทำงาน" -Summary "ตรวจสอบสิทธิ์ Administrator และ .NET Framework 4.x แล้วลองอีกครั้ง" -Kind Warning
        return
    }
    Write-Log "Supported response settings applied successfully."
    Update-Status
    Show-FreedomNotice -Title "ตั้งค่าเรียบร้อย" -Message "Apply เสร็จแล้ว พร้อมเล่น FiveM ได้" -Summary "Win32 priority: ไม่ได้เปลี่ยน`nFiveM QoS/DSCP: ตั้งค่าใน Windows แล้ว`nWindows Game Mode: เปิด`nGame DVR: ปิดการบันทึกเบื้องหลัง`nVisual effects: ปิดเอฟเฟ็กต์เดสก์ท็อปที่ไม่จำเป็น (สำรองไว้สำหรับ Revert)`nPointer precision: ปิดและสำรองค่าเดิมไว้ที่ Restore Input`nResponsiveness/MMCSS, TCP และ active physical NIC: ตั้งค่าเฉพาะค่าที่ระบบรองรับ`n$script:LastCoreSettingsSummary`nPower Plan: Core Parking/Boost/Idle ตั้งค่าในแผน Freedom Game Optimized (AC)`nTimer Service: ทำงานเฉพาะช่วง FiveM เปิดอยู่`nค่า Network/Driver อาจไม่ลด ping หรือเพิ่ม FPS; ทดสอบผลจริงหลังรีสตาร์ต" -Kind Success
    } catch {
        Show-FreedomNotice -Title "Apply ไม่สำเร็จ" -Message "เกิดข้อผิดพลาดระหว่างปรับค่า" -Summary $_.Exception.Message -Kind Error
    } finally {
        $window.Cursor = [System.Windows.Input.Cursors]::Arrow
    }
})


# CPU ACTIONS
$script:PriorityBackupPath = Join-Path $env:APPDATA "Freedom\priority_backup.xml"

function Save-Win32PriorityBackup {
    if (Test-Path -LiteralPath $script:PriorityBackupPath) {
        $existing = Import-Clixml -LiteralPath $script:PriorityBackupPath -ErrorAction Stop
        if ($null -eq $existing -or $existing -isnot [System.Management.Automation.PSCustomObject] -or $null -eq $existing.PSObject.Properties["Exists"]) {
            throw "Win32 priority Snapshot มีรูปแบบไม่ถูกต้อง"
        }
        return
    }

    $path = "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl"
    $key = Get-Item -LiteralPath $path -ErrorAction Stop
    $exists = $key.GetValueNames() -contains "Win32PrioritySeparation"
    $snapshot = [pscustomobject]@{
        Exists = $exists
        Value = if ($exists) { $key.GetValue("Win32PrioritySeparation") } else { $null }
        Kind = if ($exists) { $key.GetValueKind("Win32PrioritySeparation").ToString() } else { $null }
    }
    $backupDir = Split-Path -Parent $script:PriorityBackupPath
    if (-not (Test-Path -LiteralPath $backupDir)) {
        New-Item -Path $backupDir -ItemType Directory -Force -ErrorAction Stop | Out-Null
    }
    $snapshot | Export-Clixml -LiteralPath $script:PriorityBackupPath -ErrorAction Stop
}

function Restore-Win32Priority {
    $registryPath = "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl"
    if (-not (Test-Path -LiteralPath $script:PriorityBackupPath)) {
        Set-ItemProperty -Path $registryPath -Name "Win32PrioritySeparation" -Value 2 -Type DWord -Force -ErrorAction Stop
        return $false
    }

    $snapshot = Import-Clixml -LiteralPath $script:PriorityBackupPath -ErrorAction Stop
    if ($null -eq $snapshot -or $null -eq $snapshot.PSObject.Properties["Exists"]) {
        throw "Win32 priority Snapshot มีรูปแบบไม่ถูกต้อง"
    }
    if ($snapshot.Exists) {
        if ($snapshot.Kind -notin @("DWord", "QWord", "String", "ExpandString", "Binary", "MultiString")) {
            throw "Win32 priority Snapshot มีชนิดข้อมูลไม่ถูกต้อง"
        }
        Set-ItemProperty -Path $registryPath -Name "Win32PrioritySeparation" -Value $snapshot.Value -Type $snapshot.Kind -Force -ErrorAction Stop
    } else {
        $registryKey = Get-Item -LiteralPath $registryPath -ErrorAction Stop
        if ($registryKey.GetValueNames() -contains "Win32PrioritySeparation") {
            Remove-ItemProperty -Path $registryPath -Name "Win32PrioritySeparation" -ErrorAction Stop
        }
    }
    Remove-Item -LiteralPath $script:PriorityBackupPath -Force -ErrorAction Stop
    return $true
}

function Set-Win32Prio {
    param([int]$val, [string]$hex, [bool]$showPopup = $true)
    try {
        Save-Win32PriorityBackup
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl" -Name "Win32PrioritySeparation" -Value $val -Type DWord -Force -ErrorAction Stop
        Write-Log "Win32PrioritySeparation set to $hex"
        Update-Status
        if ($showPopup) {
            [FreedomThemedMessageBox]::Show("ตั้งค่า Win32PrioritySeparation เป็น $hex แล้ว กรุณารีสตาร์ทเครื่องเพื่อให้มีผล", "Freedom Optimizer", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information) | Out-Null
        }
    } catch {
        [FreedomThemedMessageBox]::Show("ตั้งค่า CPU priority ไม่สำเร็จ: $($_.Exception.Message)", "Freedom Optimizer", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Warning) | Out-Null
    }
}
$window.FindName("BtnCpu26").Add_Click({ Set-Win32Prio 38 "0x26" })
$window.FindName("BtnCpu28").Add_Click({ Set-Win32Prio 40 "0x28" })
$window.FindName("BtnCpu2A").Add_Click({ Set-Win32Prio 42 "0x2A" })
$window.FindName("BtnCpu24").Add_Click({ Set-Win32Prio 36 "0x24" })
$window.FindName("BtnCpu18").Add_Click({ Set-Win32Prio 24 "0x18" })
$window.FindName("BtnCpuDef").Add_Click({ Set-Win32Prio 2 "0x02 (Default)" })
$script:QosBackupPath = Join-Path $env:APPDATA "Freedom\qos_backup.xml"

function Save-QosBackup {
    if (Test-Path -LiteralPath $script:QosBackupPath) { return }
    $baseKey = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\QoS"
    $paths = @(
        $baseKey,
        "$baseKey\FiveM.exe",
        "$baseKey\FiveM_b3258_GTAProcess.exe",
        "$baseKey\FiveM_GTAProcess.exe"
    )
    $snapshot = foreach ($path in $paths) {
        $exists = Test-Path -LiteralPath $path
        $values = @()
        if ($exists) {
            $key = Get-Item -LiteralPath $path -ErrorAction Stop
            foreach ($name in $key.GetValueNames()) {
                $values += [pscustomobject]@{
                    Name = $name
                    Value = $key.GetValue($name)
                    Kind = $key.GetValueKind($name).ToString()
                }
            }
        }
        [pscustomobject]@{ Path = $path; Exists = $exists; Values = $values }
    }
    $backupDir = Split-Path -Parent $script:QosBackupPath
    if (-not (Test-Path -LiteralPath $backupDir)) {
        New-Item -Path $backupDir -ItemType Directory -Force -ErrorAction Stop | Out-Null
    }
    $snapshot | Export-Clixml -LiteralPath $script:QosBackupPath -ErrorAction Stop
}

function Restore-QosSnapshot {
    if (-not (Test-Path -LiteralPath $script:QosBackupPath)) {
        throw "ไม่พบ Snapshot ของ QoS จึงไม่สามารถคืนค่าเดิมได้"
    }
    $snapshot = Import-Clixml -LiteralPath $script:QosBackupPath -ErrorAction Stop
    $baseKey = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\QoS"
    foreach ($entry in $snapshot) {
        if (-not $entry.Exists) {
            if ($entry.Path -eq $baseKey) {
                if (Test-Path -LiteralPath $entry.Path) {
                    $key = Get-Item -LiteralPath $entry.Path -ErrorAction Stop
                    foreach ($name in @("Tcp Autotuning Level", "Application DSCP Marking Request")) {
                        if ($key.GetValueNames() -contains $name) { Remove-ItemProperty -LiteralPath $entry.Path -Name $name -ErrorAction Stop }
                    }
                }
            } elseif (Test-Path -LiteralPath $entry.Path) {
                Remove-Item -LiteralPath $entry.Path -Recurse -Force -ErrorAction Stop
            }
            continue
        }
        if (-not (Test-Path -LiteralPath $entry.Path)) {
            New-Item -Path $entry.Path -Force -ErrorAction Stop | Out-Null
        }
        $key = Get-Item -LiteralPath $entry.Path -ErrorAction Stop
        $savedNames = @($entry.Values | ForEach-Object { $_.Name })
        foreach ($name in @($key.GetValueNames())) {
            if ($savedNames -notcontains $name) { Remove-ItemProperty -LiteralPath $entry.Path -Name $name -ErrorAction Stop }
        }
        foreach ($value in $entry.Values) {
            Set-ItemProperty -LiteralPath $entry.Path -Name $value.Name -Value $value.Value -Type $value.Kind -Force -ErrorAction Stop
        }
    }
    $baseSnapshot = $snapshot | Where-Object { $_.Path -eq $baseKey } | Select-Object -First 1
    if ($baseSnapshot -and -not $baseSnapshot.Exists -and (Test-Path -LiteralPath $baseKey)) {
        $key = Get-Item -LiteralPath $baseKey -ErrorAction Stop
        $children = @(Get-ChildItem -LiteralPath $baseKey -ErrorAction Stop)
        if ($key.GetValueNames().Count -eq 0 -and $children.Count -eq 0) {
            Remove-Item -LiteralPath $baseKey -Force -ErrorAction Stop
        }
    }
    Remove-Item -LiteralPath $script:QosBackupPath -Force -ErrorAction Stop
}

function Set-FiveMQoS {
    param([bool]$ShowPopup = $true)
    Write-Log "Applying Gpedit QoS policies for FiveM..."
    Save-QosBackup
    
    $baseKey = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\QoS"
    if (-not (Test-Path -LiteralPath $baseKey)) { New-Item -Path $baseKey -Force -ErrorAction Stop | Out-Null }
    
    Set-ItemProperty -Path $baseKey -Name "Tcp Autotuning Level" -Value "Normal" -Type String -Force -ErrorAction Stop
    Set-ItemProperty -Path $baseKey -Name "Application DSCP Marking Request" -Value "Ignored" -Type String -Force -ErrorAction Stop
    
    $policies = @(
        @{
            Path = "$baseKey\FiveM.exe"
            Values = [ordered]@{
                "Version" = "1.0"
                "Application Name" = "FiveM.exe"
                "Protocol" = "*"
                "Local Port" = "*"
                "Local IP" = "*"
                "Local IP Prefix Length" = "*"
                "Remote Port" = "*"
                "Remote IP" = "*"
                "Remote IP Prefix Length" = "*"
                "DSCP Value" = "46"
                "Throttle Rate" = "-1"
            }
        },
        @{
            Path = "$baseKey\FiveM_b3258_GTAProcess.exe"
            Values = [ordered]@{
                "Version" = "1.0"
                "Application Name" = "FiveM_b3258_GTAProcess.exe"
                "Protocol" = "UDP"
                "Local Port" = "*"
                "Local IP" = "*"
                "Local IP Prefix Length" = "*"
                "Remote Port" = "*"
                "Remote IP" = "*"
                "Remote IP Prefix Length" = "*"
                "DSCP Value" = "46"
                "Throttle Rate" = "-1"
            }
        },
        @{
            Path = "$baseKey\FiveM_GTAProcess.exe"
            Values = [ordered]@{
                "Version" = "1.0"
                "Application Name" = "FiveM_GTAProcess.exe"
                "Protocol" = "UDP"
                "Local Port" = "*"
                "Local IP" = "*"
                "Local IP Prefix Length" = "*"
                "Remote Port" = "*"
                "Remote IP" = "*"
                "Remote IP Prefix Length" = "*"
                "DSCP Value" = "46"
                "Throttle Rate" = "-1"
            }
        }
    )
    
    foreach ($p in $policies) {
        if (-not (Test-Path -LiteralPath $p.Path)) { New-Item -Path $p.Path -Force -ErrorAction Stop | Out-Null }
        foreach ($name in $p.Values.Keys) {
            Set-ItemProperty -Path $p.Path -Name $name -Value $p.Values[$name] -Type String -Force -ErrorAction Stop
        }
    }
    
    Write-Log "Gpedit QoS policies applied successfully."
    Update-Status
    if ($ShowPopup) {
        [FreedomThemedMessageBox]::Show("Successfully!

ตั้งค่า Gpedit QoS สำหรับ FiveM เรียบร้อยแล้ว
(DSCP 46 อาจถูกละเว้นโดย Router/ISP และไม่ได้รับประกัน ping ต่ำลง)", "Freedom Optimizer", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information) | Out-Null
    }
}

function Restore-FiveMQoS {
    Write-Log "Restoring Gpedit QoS policies..."
    Restore-QosSnapshot
    Write-Log "Gpedit QoS policies restored."
    Update-Status
    [FreedomThemedMessageBox]::Show("คืนค่า QoS ก่อนปรับเรียบร้อยแล้ว", "Freedom Optimizer", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information) | Out-Null
}

$window.FindName("BtnUnpark").Add_Click({
    try { Set-FiveMQoS } catch {
        [FreedomThemedMessageBox]::Show("ตั้งค่า QoS ไม่สำเร็จ: $($_.Exception.Message)", "Freedom Optimizer", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Warning) | Out-Null
    }
})
$window.FindName("BtnPark").Add_Click({
    try { Restore-FiveMQoS } catch {
        [FreedomThemedMessageBox]::Show("คืนค่า QoS ไม่สำเร็จ: $($_.Exception.Message)", "Freedom Optimizer", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Warning) | Out-Null
    }
})

# INPUT ACTIONS
$script:InputBackupPath = Join-Path $env:APPDATA "Freedom\input_backup.xml"
$script:InputValues = @(
    @{ Path = "HKCU:\Control Panel\Mouse"; Name = "MouseSensitivity" },
    @{ Path = "HKCU:\Control Panel\Mouse"; Name = "MouseSpeed" },
    @{ Path = "HKCU:\Control Panel\Mouse"; Name = "MouseThreshold1" },
    @{ Path = "HKCU:\Control Panel\Mouse"; Name = "MouseThreshold2" },
    @{ Path = "HKCU:\Control Panel\Keyboard"; Name = "KeyboardDelay" },
    @{ Path = "HKCU:\Control Panel\Keyboard"; Name = "KeyboardSpeed" }
)

function Save-InputBackup {
    if (Test-Path -LiteralPath $script:InputBackupPath) { return }
    $snapshot = foreach ($entry in $script:InputValues) {
        $key = Get-Item -LiteralPath $entry.Path -ErrorAction Stop
        $exists = $key.GetValueNames() -contains $entry.Name
        [pscustomobject]@{
            Path = $entry.Path
            Name = $entry.Name
            Exists = $exists
            Value = if ($exists) { $key.GetValue($entry.Name) } else { $null }
            Kind = if ($exists) { $key.GetValueKind($entry.Name).ToString() } else { $null }
        }
    }
    $backupDir = Split-Path -Parent $script:InputBackupPath
    if (-not (Test-Path -LiteralPath $backupDir)) {
        New-Item -Path $backupDir -ItemType Directory -Force -ErrorAction Stop | Out-Null
    }
    $snapshot | Export-Clixml -LiteralPath $script:InputBackupPath -ErrorAction Stop
}

function Restore-InputSettings {
    if (-not (Test-Path -LiteralPath $script:InputBackupPath)) {
        throw "ไม่พบข้อมูลสำรอง Input จึงไม่สามารถคืนค่าเดิมได้"
    }
    $snapshot = Import-Clixml -LiteralPath $script:InputBackupPath -ErrorAction Stop
    foreach ($entry in $snapshot) {
        $key = Get-Item -LiteralPath $entry.Path -ErrorAction Stop
        if ($entry.Exists) {
            Set-ItemProperty -LiteralPath $entry.Path -Name $entry.Name -Value $entry.Value -Type $entry.Kind -Force -ErrorAction Stop
        } elseif ($key.GetValueNames() -contains $entry.Name) {
            Remove-ItemProperty -LiteralPath $entry.Path -Name $entry.Name -ErrorAction Stop
        }
    }
    Remove-Item -LiteralPath $script:InputBackupPath -Force -ErrorAction Stop
}

function Set-FreedomPointerPrecision {
    Save-InputBackup
    Set-ItemProperty -LiteralPath "HKCU:\Control Panel\Mouse" -Name "MouseSpeed" -Value "0" -Force -ErrorAction Stop
    Set-ItemProperty -LiteralPath "HKCU:\Control Panel\Mouse" -Name "MouseThreshold1" -Value "0" -Force -ErrorAction Stop
    Set-ItemProperty -LiteralPath "HKCU:\Control Panel\Mouse" -Name "MouseThreshold2" -Value "0" -Force -ErrorAction Stop
    if (-not ("FreedomNativeInput" -as [type])) {
        Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public static class FreedomNativeInput {
    [DllImport("user32.dll", SetLastError = true)]
    public static extern bool SystemParametersInfo(uint action, uint param, ref int value, uint flags);
}
"@ -ErrorAction Stop
    }
    $mouse = [int[]]@(0, 0, 0)
    if (-not [FreedomNativeInput]::SystemParametersInfo(0x0004, 0, [ref]$mouse[0], 0x0001 -bor 0x0002)) {
        throw "Windows refused to apply the pointer-precision setting immediately; the backed-up registry values were written."
    }
}

function Get-FreedomCitizenFxConfigPath {
    $candidates = @(
        (Join-Path $env:LOCALAPPDATA "FiveM\FiveM.app\citizenfx.ini"),
        (Join-Path $env:LOCALAPPDATA "FiveM\citizenfx.ini")
    )
    return ($candidates | Where-Object { Test-Path -LiteralPath $_ -PathType Leaf } | Select-Object -First 1)
}

function Update-FreedomSystemDiagnostics {
    $lines = [System.Collections.Generic.List[string]]::new()
    try {
        $computer = Get-CimInstance -ClassName Win32_ComputerSystem -ErrorAction Stop
        $ramGb = [math]::Round($computer.TotalPhysicalMemory / 1GB, 1)
        $lines.Add("RAM: $ramGb GB")
    } catch {
        $ramGb = 0
        $lines.Add("RAM: unavailable ($($_.Exception.Message))")
    }

    try {
        $mouse = Get-ItemProperty -LiteralPath "HKCU:\Control Panel\Mouse" -ErrorAction Stop
        $mouseOn = ($mouse.MouseSpeed -eq "0" -and $mouse.MouseThreshold1 -eq "0" -and $mouse.MouseThreshold2 -eq "0")
        $queueMouse = (Get-ItemProperty -LiteralPath "HKLM:\SYSTEM\CurrentControlSet\Services\Mouclass\Parameters" -Name MouseDataQueueSize -ErrorAction SilentlyContinue).MouseDataQueueSize
        $queueKeyboard = (Get-ItemProperty -LiteralPath "HKLM:\SYSTEM\CurrentControlSet\Services\Kbdclass\Parameters" -Name KeyboardDataQueueSize -ErrorAction SilentlyContinue).KeyboardDataQueueSize
        $window.FindName("TxtInputStatus").Text = "Pointer precision: $(if ($mouseOn) { 'disabled' } else { 'Windows default/changed' }) | Mouse queue: $(if ($null -eq $queueMouse) { 'default' } else { $queueMouse }) | Keyboard queue: $(if ($null -eq $queueKeyboard) { 'default' } else { $queueKeyboard }). Polling rate and USB hub path are not reliably exposed by Windows."
    } catch {
        $window.FindName("TxtInputStatus").Text = "Could not read input settings: $($_.Exception.Message)"
    }

    try {
        $trim = fsutil behavior query DisableDeleteNotify 2>&1
        if ($LASTEXITCODE -ne 0) { throw ($trim -join " ") }
        $lines.Add("TRIM: $($trim -join '; ')")
    } catch {
        $lines.Add("TRIM: unavailable ($($_.Exception.Message))")
    }

    try {
        $physicalDisks = @(Get-PhysicalDisk -ErrorAction Stop | ForEach-Object { "$($_.FriendlyName): $($_.MediaType)" })
        if ($physicalDisks.Count) { $lines.Add("Physical drives: $($physicalDisks -join '; ')") }
        else { $lines.Add("Physical drives: Windows reported none") }
    } catch {
        $lines.Add("Physical drives: unavailable ($($_.Exception.Message))")
    }

    try {
        $pagefile = Get-CimInstance -ClassName Win32_ComputerSystem -ErrorAction Stop
        $pagefileUsage = @(Get-CimInstance -ClassName Win32_PageFileUsage -ErrorAction Stop)
        $pagefileText = if ($pagefileUsage.Count) { ($pagefileUsage | ForEach-Object { "$($_.Name) ($($_.AllocatedBaseSize) MB allocated)" }) -join "; " } else { "no active pagefile reported" }
        $lines.Add("Page file: automatic=$($pagefile.AutomaticManagedPagefile); $pagefileText")
    } catch {
        $lines.Add("Page file: unavailable ($($_.Exception.Message))")
    }

    try {
        $agent = Get-MMAgent -ErrorAction Stop
        $lines.Add("Memory compression: $($agent.MemoryCompression)")
    } catch {
        $lines.Add("Memory compression: status unavailable ($($_.Exception.Message))")
    }

    try {
        $deviceGuard = Get-CimInstance -Namespace "root\Microsoft\Windows\DeviceGuard" -ClassName Win32_DeviceGuard -ErrorAction Stop
        $lines.Add("VBS status: $($deviceGuard.VirtualizationBasedSecurityStatus); Memory Integrity services running: $($deviceGuard.SecurityServicesRunning -join ',')")
    } catch {
        $lines.Add("VBS/Memory Integrity: status unavailable ($($_.Exception.Message))")
    }

    try {
        $defender = Get-MpComputerStatus -ErrorAction Stop
        $lines.Add("Defender real-time protection: $($defender.RealTimeProtectionEnabled) (status only; no Defender settings are changed)")
    } catch {
        $lines.Add("Defender: status unavailable ($($_.Exception.Message))")
    }

    try {
        $directX = Get-ItemProperty -LiteralPath "HKLM:\SOFTWARE\Microsoft\DirectX" -Name Version -ErrorAction Stop
        $lines.Add("Installed DirectX runtime: $($directX.Version); FiveM's active DX mode is not inferred unless configured in its files.")
    } catch {
        $lines.Add("DirectX version: unavailable ($($_.Exception.Message))")
    }

    $config = Get-FreedomCitizenFxConfigPath
    if ($config) {
        $lines.Add("CitizenFX config: $config")
        try {
            $configLines = @(Get-Content -LiteralPath $config -ErrorAction Stop)
            $interesting = @($configLines | Where-Object { $_ -match '(?i)dx12|directx|graphics|renderer' } | Select-Object -First 10)
            if ($interesting.Count) { $lines.Add("CitizenFX hints: $($interesting -join '; ')") }
            else { $lines.Add("CitizenFX hints: no renderer/DirectX setting found") }
        } catch {
            $lines.Add("CitizenFX config could not be read: $($_.Exception.Message)")
        }
    } else {
        $lines.Add("CitizenFX config: not found in the standard FiveM locations")
    }

    $cachePaths = @(
        (Join-Path $env:LOCALAPPDATA "FiveM\FiveM.app\data\cache"),
        (Join-Path $env:LOCALAPPDATA "FiveM\FiveM.app\data\server-cache"),
        (Join-Path $env:LOCALAPPDATA "FiveM\FiveM.app\data\server-cache-priv")
    )
    $totalCacheSize = [int64]0
    $cacheFound = $false
    foreach ($cachePath in $cachePaths) {
        if (Test-Path -LiteralPath $cachePath) {
            $cacheFound = $true
            $size = Get-DirSize $cachePath
            if ($null -eq $size) { $lines.Add("FiveM cache $($cachePath): size unavailable") }
            else {
                $totalCacheSize += $size
            }
        }
    }
    if ($cacheFound) {
        $totalCacheGb = [math]::Round($totalCacheSize / 1GB, 2)
        $lines.Add("FiveM cache total: $totalCacheGb GB$(if ($totalCacheSize -gt 5GB) { ' (over 5 GB; inspect before cleaning)' })")
    } else {
        $lines.Add("FiveM cache: standard cache directories not found")
    }
    if ($ramGb -gt 0 -and $ramGb -lt 16) { $lines.Add("Warning: RAM below 16 GB; do not disable Memory Compression.") }
    try {
        $largeCache = (Get-ItemProperty -LiteralPath "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" -Name LargeSystemCache -ErrorAction SilentlyContinue).LargeSystemCache
        $lines.Add("LargeSystemCache: $(if ($null -eq $largeCache) { 'Windows default' } else { $largeCache }); informational only.")
    } catch { $lines.Add("LargeSystemCache: status unavailable ($($_.Exception.Message))") }
    $lines.Add("Storage Sense: no files are removed automatically while gaming; review Windows Storage settings manually.")
    $lines.Add("USB selective suspend is power-plan based and cannot be safely toggled per-device here; polling rate/hub path are not reliably exposed by Windows.")

    try {
        $mpo = (Get-ItemProperty -LiteralPath "HKLM:\SOFTWARE\Microsoft\Windows\Dwm" -Name DisableOverlays -ErrorAction SilentlyContinue).DisableOverlays
        $window.FindName("TxtDwmStatus").Text = "DisableOverlays: $(if ($null -eq $mpo) { 'Windows default / not set' } else { $mpo }); DWM frame-latency registry tuning omitted because no reliable universal setting is established."
    } catch {
        $window.FindName("TxtDwmStatus").Text = "MPO status unavailable: $($_.Exception.Message)"
    }
    $window.FindName("TxtSystemDiagnostics").Text = $lines -join "`n"

    try {
        $profiles = @(Get-NetConnectionProfile -ErrorAction Stop)
        $combo = $window.FindName("CmbNetworkProfile")
        $combo.Items.Clear()
        foreach ($profile in $profiles) {
            $combo.Items.Add([pscustomobject]@{
                Name = "$($profile.Name) [$($profile.InterfaceAlias), ifIndex $($profile.InterfaceIndex)] — $($profile.NetworkCategory)"
                Profile = $profile
            }) | Out-Null
        }
        if ($combo.Items.Count -gt 0) { $combo.SelectedIndex = 0 }
        $window.FindName("TxtNetworkProfileStatus").Text = if ($profiles.Count) {
            ($profiles | ForEach-Object { "$($_.Name): $($_.NetworkCategory) ($($_.InterfaceAlias))" }) -join "`n"
        } else { "No active network profile was reported." }
    } catch {
        $window.FindName("TxtNetworkProfileStatus").Text = "Network profiles unavailable: $($_.Exception.Message)"
    }
}

function Update-FreedomStartupList {
    $list = $window.FindName("LstStartupApps")
    $list.Items.Clear()
    $sources = @(
        @{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"; Label = "Current user Run" },
        @{ Path = "HKLM:\Software\Microsoft\Windows\CurrentVersion\Run"; Label = "Machine Run" },
        @{ Path = "HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Run"; Label = "32-bit Machine Run" }
    )
    foreach ($source in $sources) {
        if (-not (Test-Path -LiteralPath $source.Path)) { continue }
        try {
            $properties = Get-ItemProperty -LiteralPath $source.Path -ErrorAction Stop
            foreach ($property in $properties.PSObject.Properties | Where-Object { $_.Name -notmatch '^PS' }) {
                $list.Items.Add("$($source.Label): $($property.Name) — $($property.Value)") | Out-Null
            }
        } catch {
            $list.Items.Add("$($source.Label): read failed — $($_.Exception.Message)") | Out-Null
        }
    }
    foreach ($folder in @([Environment]::GetFolderPath("Startup"), [Environment]::GetFolderPath("CommonStartup"))) {
        if (-not $folder -or -not (Test-Path -LiteralPath $folder)) { continue }
        try {
            foreach ($file in Get-ChildItem -LiteralPath $folder -Force -ErrorAction Stop) {
                $list.Items.Add("Startup folder: $($file.Name)") | Out-Null
            }
        } catch {
            $list.Items.Add("Startup folder read failed: $($_.Exception.Message)") | Out-Null
        }
    }
    if ($list.Items.Count -eq 0) { $list.Items.Add("No startup entries found in the checked locations.") | Out-Null }
}

$window.FindName("BtnInputMouse").Add_Click({
    try {
        Set-FreedomPointerPrecision
        [FreedomThemedMessageBox]::Show("ปิด Mouse Acceleration แล้ว โดยไม่เปลี่ยนความไวเมาส์หรือคีย์บอร์ด สามารถคืนค่าเดิมได้ด้วยปุ่ม Restore`n`nอาจต้องออกจากระบบหรือรีสตาร์ทเพื่อให้บางแอปใช้ค่าทันที", "Freedom Optimizer") | Out-Null
    } catch {
        [FreedomThemedMessageBox]::Show("ปรับค่า Input ไม่สำเร็จ: $($_.Exception.Message)", "Freedom Optimizer", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Warning) | Out-Null
    }
})
$window.FindName("BtnInputRestore").Add_Click({
    try {
        Restore-InputSettings
        $mouse = [int[]]@([int](Get-ItemProperty -LiteralPath "HKCU:\Control Panel\Mouse" -Name MouseSpeed).MouseSpeed, [int](Get-ItemProperty -LiteralPath "HKCU:\Control Panel\Mouse" -Name MouseThreshold1).MouseThreshold1, [int](Get-ItemProperty -LiteralPath "HKCU:\Control Panel\Mouse" -Name MouseThreshold2).MouseThreshold2)
        if ("FreedomNativeInput" -as [type]) {
            [void][FreedomNativeInput]::SystemParametersInfo(0x0004, 0, [ref]$mouse[0], 0x0001 -bor 0x0002)
        }
        [FreedomThemedMessageBox]::Show("คืนค่า Input เดิมเรียบร้อยแล้ว", "Freedom Optimizer") | Out-Null
    } catch {
        [FreedomThemedMessageBox]::Show("คืนค่า Input ไม่สำเร็จ: $($_.Exception.Message)", "Freedom Optimizer", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Warning) | Out-Null
    }
})

$window.FindName("BtnInputApply").Add_Click({
    try {
        Set-FreedomPointerPrecision
        Update-FreedomSystemDiagnostics
        Show-BoostMsg "ปิด pointer acceleration/precision แล้ว สำรองค่าเดิมไว้ที่ Restore Input และอัปเดตค่าทันทีแล้ว"
    } catch {
        [FreedomThemedMessageBox]::Show("ปรับ pointer precision ไม่สำเร็จ: $($_.Exception.Message)", "Freedom Optimizer", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error) | Out-Null
    }
})
$window.FindName("BtnInputQueueApply").Add_Click({
    try {
        $selected = $window.FindName("CmbInputQueue").SelectedItem
        if (-not $selected) { throw "เลือกขนาด queue ก่อน" }
        $queueSize = [int]$selected.Content
        if ($queueSize -notin @(20, 24, 32)) { throw "ค่าขนาด queue ไม่ถูกต้อง" }
        Set-BoostReg "HKLM:\SYSTEM\CurrentControlSet\Services\Mouclass\Parameters" "MouseDataQueueSize" $queueSize
        Set-BoostReg "HKLM:\SYSTEM\CurrentControlSet\Services\Kbdclass\Parameters" "KeyboardDataQueueSize" $queueSize
        Save-BoostBk
        Update-FreedomSystemDiagnostics
        Show-BoostMsg "ตั้ง MouseDataQueueSize และ KeyboardDataQueueSize เป็น $queueSize แล้ว ค่าเดิมสำรองไว้ที่ Boost → Revert ต้องรีสตาร์ต Windows; ค่านี้ไม่เปลี่ยนอัตรา polling ของอุปกรณ์"
    } catch {
        [FreedomThemedMessageBox]::Show("ปรับ queue size ไม่สำเร็จ: $($_.Exception.Message)", "Freedom Optimizer", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error) | Out-Null
    }
})

$window.FindName("BtnVisualApply").Add_Click({
    $selected = @(
        [bool]$window.FindName("ChkTransparency").IsChecked,
        [bool]$window.FindName("ChkAnimations").IsChecked,
        [bool]$window.FindName("ChkShadows").IsChecked,
        [bool]$window.FindName("ChkFullscreenOptimization").IsChecked
    )
    if (-not ($selected -contains $true)) {
        Show-BoostMsg "ไม่ได้เลือกค่าที่จะเปลี่ยน"
        return
    }
    $confirm = [FreedomThemedMessageBox]::Show("จะเปลี่ยนเฉพาะตัวเลือกที่เลือกไว้ การตั้งค่าเดิมจะถูกสำรองไว้ที่ Boost → Revert; อาจต้องออกจากระบบหรือรีสตาร์ต Explorer. ดำเนินการต่อหรือไม่?", "Desktop Effects", [System.Windows.MessageBoxButton]::YesNo, [System.Windows.MessageBoxImage]::Warning)
    if ($confirm -ne [System.Windows.MessageBoxResult]::Yes) { return }
    try {
        if ($window.FindName("ChkTransparency").IsChecked) {
            Set-BoostReg "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" "EnableTransparency" 0
        }
        if ($window.FindName("ChkAnimations").IsChecked) {
            Set-BoostReg "HKCU:\Control Panel\Desktop\WindowMetrics" "MinAnimate" "0" "String"
            Set-BoostReg "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "TaskbarAnimations" 0
        }
        if ($window.FindName("ChkShadows").IsChecked) {
            Set-BoostReg "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "ListviewShadow" 0
        }
        if ($window.FindName("ChkFullscreenOptimization").IsChecked) {
            $fiveMExe = @(
                (Join-Path $env:LOCALAPPDATA "FiveM\FiveM.exe"),
                (Join-Path $env:LOCALAPPDATA "FiveM\FiveM.app\FiveM.exe")
            ) | Where-Object { Test-Path -LiteralPath $_ -PathType Leaf } | Select-Object -First 1
            if (-not $fiveMExe) { throw "ไม่พบ FiveM.exe ในตำแหน่งมาตรฐาน จึงยังไม่ตั้งค่า Fullscreen Optimizations" }
            $compatPath = "HKCU:\Software\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Layers"
            $existing = if (Test-Path -LiteralPath $compatPath) { (Get-Item -LiteralPath $compatPath -ErrorAction Stop).GetValue($fiveMExe) } else { $null }
            $tokens = @(([string]$existing -split '\s+') | Where-Object { $_ })
            if ($tokens -notcontains "DISABLEDXMAXIMIZEDWINDOWEDMODE") { $tokens += "DISABLEDXMAXIMIZEDWINDOWEDMODE" }
            Set-BoostReg $compatPath $fiveMExe ($tokens -join " ") "String"
        }
        Save-BoostBk
        Show-BoostMsg "ปรับ visual settings ที่เลือกแล้ว ค่าเดิมสำรองไว้ที่ Boost → Revert"
    } catch {
        [FreedomThemedMessageBox]::Show("ปรับ visual settings ไม่สำเร็จหรือได้เพียงบางส่วน: $($_.Exception.Message)", "Freedom Optimizer", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error) | Out-Null
    }
})

$window.FindName("BtnMpoApply").Add_Click({
    if (-not $window.FindName("ChkMpoDisable").IsChecked) {
        Show-BoostMsg "ไม่ได้เลือก Disable MPO จึงไม่มีการเปลี่ยนค่า"
        return
    }
    $confirm = [FreedomThemedMessageBox]::Show("การปิด MPO เป็นการทดลองเฉพาะแก้ปัญหาภาพกะพริบ/กระตุกบางระบบ อาจทำให้วิดีโอหรือประสิทธิภาพแย่ลง และต้องรีสตาร์ต ใช้ A/B test และคืนค่าได้จาก Boost → Revert. ดำเนินการต่อหรือไม่?", "Experimental MPO Warning", [System.Windows.MessageBoxButton]::YesNo, [System.Windows.MessageBoxImage]::Warning)
    if ($confirm -ne [System.Windows.MessageBoxResult]::Yes) { return }
    try {
        Set-BoostReg "HKLM:\SOFTWARE\Microsoft\Windows\Dwm" "DisableOverlays" 1
        Save-BoostBk
        $window.FindName("TxtDwmStatus").Text = "DisableOverlays=1 set. Restart required; restore through Boost → Revert and compare results."
        Show-BoostMsg "ตั้งค่า DisableOverlays=1 แล้ว รีสตาร์ตเพื่อทดสอบ; ค่าก่อนหน้าถูกสำรองไว้"
    } catch {
        [FreedomThemedMessageBox]::Show("ตั้งค่า MPO ไม่สำเร็จ: $($_.Exception.Message)", "Freedom Optimizer", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error) | Out-Null
    }
})

$window.FindName("BtnSystemRefresh").Add_Click({
    try { Update-FreedomSystemDiagnostics; Update-FreedomStartupList } catch {
        [FreedomThemedMessageBox]::Show("อัปเดตข้อมูลระบบไม่สำเร็จ: $($_.Exception.Message)", "Freedom Optimizer", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Warning) | Out-Null
    }
})
$window.FindName("BtnStartupRefresh").Add_Click({ Update-FreedomStartupList })

$window.FindName("BtnFiveMConfigBackup").Add_Click({
    try {
        $config = Get-FreedomCitizenFxConfigPath
        if (-not $config) { throw "ไม่พบ citizenfx.ini ในตำแหน่ง FiveM มาตรฐาน" }
        if (-not (Test-Path -LiteralPath $script:BoostDir)) { New-Item -Path $script:BoostDir -ItemType Directory -Force -ErrorAction Stop | Out-Null }
        $backupPath = Join-Path $script:BoostDir "citizenfx.ini.backup"
        $manifestPath = Join-Path $script:BoostDir "citizenfx.ini.backup.path"
        if (Test-Path -LiteralPath $backupPath) { throw "มี citizenfx.ini backup อยู่แล้ว ($backupPath); Restore หรือย้ายไฟล์ backup ก่อนสร้างใหม่" }
        Copy-Item -LiteralPath $config -Destination $backupPath -ErrorAction Stop
        Set-Content -LiteralPath $manifestPath -Value $config -Encoding UTF8 -ErrorAction Stop
        Show-BoostMsg "สำรอง CitizenFX config แล้ว:`n$config`n`nBackup: $backupPath"
    } catch {
        [FreedomThemedMessageBox]::Show("สำรอง CitizenFX config ไม่สำเร็จ: $($_.Exception.Message)", "Freedom Optimizer", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error) | Out-Null
    }
})
$window.FindName("BtnFiveMConfigRestore").Add_Click({
    try {
        $backupPath = Join-Path $script:BoostDir "citizenfx.ini.backup"
        $manifestPath = Join-Path $script:BoostDir "citizenfx.ini.backup.path"
        if (-not (Test-Path -LiteralPath $backupPath) -or -not (Test-Path -LiteralPath $manifestPath)) { throw "ไม่พบ CitizenFX backup ที่สมบูรณ์" }
        $config = (Get-Content -LiteralPath $manifestPath -Raw -ErrorAction Stop).Trim()
        if ([string]::IsNullOrWhiteSpace($config)) { throw "ไม่พบตำแหน่ง config ใน manifest" }
        $confirm = [FreedomThemedMessageBox]::Show("จะคืนค่า CitizenFX config จาก backup ไปยัง:`n$config`n`nดำเนินการต่อหรือไม่?", "Restore CitizenFX Config", [System.Windows.MessageBoxButton]::YesNo, [System.Windows.MessageBoxImage]::Warning)
        if ($confirm -ne [System.Windows.MessageBoxResult]::Yes) { return }
        if (Test-Path -LiteralPath $config) {
            $beforeRestore = "$config.pre-restore-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
            Copy-Item -LiteralPath $config -Destination $beforeRestore -ErrorAction Stop
        } else {
            $parent = Split-Path -Parent $config
            if (-not (Test-Path -LiteralPath $parent)) { New-Item -Path $parent -ItemType Directory -Force -ErrorAction Stop | Out-Null }
        }
        Copy-Item -LiteralPath $backupPath -Destination $config -Force -ErrorAction Stop
        Show-BoostMsg "คืนค่า CitizenFX config แล้ว สำเนาก่อน Restore (ถ้ามี) อยู่ที่ $beforeRestore"
    } catch {
        [FreedomThemedMessageBox]::Show("คืนค่า CitizenFX config ไม่สำเร็จ: $($_.Exception.Message)", "Freedom Optimizer", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error) | Out-Null
    }
})

$window.FindName("BtnMemoryCompression").Add_Click({
    try {
        if ($script:BoostBackupLoadError) { throw "อ่าน Snapshot เดิมไม่ได้ จึงระงับการเปลี่ยนแปลง: $($script:BoostBackupLoadError)" }
        $computer = Get-CimInstance -ClassName Win32_ComputerSystem -ErrorAction Stop
        $ramGb = [math]::Round($computer.TotalPhysicalMemory / 1GB, 1)
        if ($ramGb -lt 32) { throw "Memory Compression toggle ถูกจำกัดไว้สำหรับ RAM ตั้งแต่ 32 GB ขึ้นไป (ตรวจพบ $ramGb GB)" }
        $agent = Get-MMAgent -ErrorAction Stop
        if (-not $agent.MemoryCompression) { Show-BoostMsg "Memory Compression ปิดอยู่แล้ว"; return }
        $confirm = [FreedomThemedMessageBox]::Show("ปิด Memory Compression บนเครื่อง RAM $ramGb GB หรือไม่? อาจเพิ่มการใช้ RAM และทำให้ paging/stutter แย่ลง; ไม่มีการรับประกัน FPS. ค่าเดิมถูกสำรองและคืนได้จาก Boost → Revert.", "Memory Compression Warning", [System.Windows.MessageBoxButton]::YesNo, [System.Windows.MessageBoxImage]::Warning)
        if ($confirm -ne [System.Windows.MessageBoxResult]::Yes) { return }
        $key = "MMAGENT|MemoryCompression"
        if (-not $script:BoostBk.ContainsKey($key)) {
            $script:BoostBk[$key] = @{ Enabled = [bool]$agent.MemoryCompression }
            Save-BoostBk
        }
        Disable-MMAgent -MemoryCompression -ErrorAction Stop
        Show-BoostMsg "ปิด Memory Compression แล้ว คืนค่าเดิมได้จาก Boost → Revert; อาจต้องรีสตาร์ต"
        Update-FreedomSystemDiagnostics
    } catch {
        [FreedomThemedMessageBox]::Show("ปิด Memory Compression ไม่สำเร็จ: $($_.Exception.Message)", "Freedom Optimizer", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error) | Out-Null
    }
})

function Update-FreedomOptionalTasks {
    $list = $window.FindName("LstOptionalTasks")
    $list.Items.Clear()
    try {
        $tasks = @(Get-ScheduledTask -ErrorAction Stop | Where-Object {
            $_.TaskPath -match '^\\Microsoft\\Windows\\(Application Experience|Feedback|DiskDiagnostic)\\'
        })
        foreach ($task in $tasks) {
            $list.Items.Add([pscustomobject]@{
                Display = "$($task.TaskPath)$($task.TaskName) [$($task.State)]"
                TaskPath = $task.TaskPath
                TaskName = $task.TaskName
                Enabled = ($task.State -ne "Disabled")
            }) | Out-Null
        }
        $list.DisplayMemberPath = "Display"
        if (-not $tasks.Count) { $list.Items.Add("No matching scheduled tasks found.") | Out-Null }
    } catch {
        $list.Items.Add("Task scan failed: $($_.Exception.Message)") | Out-Null
    }
}
$window.FindName("BtnTasksRefresh").Add_Click({ Update-FreedomOptionalTasks })
$window.FindName("BtnTasksDisable").Add_Click({
    $selected = @($window.FindName("LstOptionalTasks").SelectedItems | Where-Object { $_ -isnot [string] })
    if (-not $selected.Count) { Show-BoostMsg "เลือก task ที่ต้องการก่อน"; return }
    $confirm = [FreedomThemedMessageBox]::Show("จะ Disable เฉพาะ task ที่เลือก และสำรองสถานะเดิมของแต่ละรายการก่อนเปลี่ยน. ดำเนินการต่อหรือไม่?", "Scheduled Tasks Warning", [System.Windows.MessageBoxButton]::YesNo, [System.Windows.MessageBoxImage]::Warning)
    if ($confirm -ne [System.Windows.MessageBoxResult]::Yes) { return }
    $errors = [System.Collections.Generic.List[string]]::new()
    foreach ($item in $selected) {
        if (-not $item.Enabled) { continue }
        try {
            $key = "TASK|$($item.TaskPath)$($item.TaskName)"
            if (-not $script:BoostBk.ContainsKey($key)) {
                $script:BoostBk[$key] = @{ TaskPath = $item.TaskPath; TaskName = $item.TaskName; Enabled = $true }
                Save-BoostBk
            }
            $task = Get-ScheduledTask -TaskPath $item.TaskPath -TaskName $item.TaskName -ErrorAction Stop
            Disable-ScheduledTask -InputObject $task -ErrorAction Stop | Out-Null
        } catch {
            $errors.Add("$($item.TaskPath)$($item.TaskName): $($_.Exception.Message)")
        }
    }
    Update-FreedomOptionalTasks
    if ($errors.Count) {
        [FreedomThemedMessageBox]::Show("บาง task ปิดไม่สำเร็จ:`n$($errors -join "`n")`n`nSnapshot ยังคงอยู่สำหรับ Restore.", "Freedom Optimizer", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Warning) | Out-Null
    } else {
        Show-BoostMsg "ปิด task ที่เลือกแล้ว; Restore ได้จาก Boost → Revert"
    }
})

$window.FindName("BtnConsumerFeatures").Add_Click({
    $confirm = [FreedomThemedMessageBox]::Show("จะปิด Windows Tips/Consumer suggestions และ Background Apps สำหรับผู้ใช้ปัจจุบัน พร้อมบันทึกค่าเดิม. แอปบางตัวอาจไม่ได้รับการอัปเดตเบื้องหลัง. ดำเนินการต่อหรือไม่?", "Background Features Warning", [System.Windows.MessageBoxButton]::YesNo, [System.Windows.MessageBoxImage]::Warning)
    if ($confirm -ne [System.Windows.MessageBoxResult]::Yes) { return }
    try {
        Set-BoostReg "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" "SoftLandingEnabled" 0
        Set-BoostReg "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" "SubscribedContent-338388Enabled" 0
        Set-BoostReg "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" "SubscribedContent-338389Enabled" 0
        Set-BoostReg "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "ShowSyncProviderNotifications" 0
        Set-BoostReg "HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" "GlobalUserDisabled" 1
        Set-BoostReg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" "DisableWindowsConsumerFeatures" 1
        Save-BoostBk
        Show-BoostMsg "ตั้งค่า Windows Tips/Consumer Features และ Background Apps แล้ว; คืนค่าได้จาก Boost → Revert"
    } catch {
        [FreedomThemedMessageBox]::Show("ปรับ Background Features ไม่สำเร็จหรือได้เพียงบางส่วน: $($_.Exception.Message)", "Freedom Optimizer", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error) | Out-Null
    }
})

$window.FindName("CmbGamingDns").Add_SelectionChanged({
    $choice = $window.FindName("CmbGamingDns").SelectedIndex
    $recommendation = switch ($choice) {
        1 { "Cloudflare: 1.1.1.1 / 1.0.0.1 (recommendation only)" }
        2 { "Quad9: 9.9.9.9 / 149.112.112.112 (recommendation only)" }
        default { "No DNS change selected" }
    }
    $window.FindName("TxtNetworkProfileStatus").Text = "$($window.FindName('TxtNetworkProfileStatus').Text)`n$recommendation"
})
$window.FindName("BtnNetworkProfilePrivate").Add_Click({
    $selected = $window.FindName("CmbNetworkProfile").SelectedItem
    if (-not $selected -or -not $selected.Profile) { Show-BoostMsg "เลือก network profile ก่อน"; return }
    if ($selected.Profile.NetworkCategory -eq "Private") { Show-BoostMsg "Network profile นี้เป็น Private อยู่แล้ว"; return }
    $confirm = [FreedomThemedMessageBox]::Show("เปลี่ยน '$($selected.Profile.Name)' ($($selected.Profile.InterfaceAlias)) เป็น Private ได้เฉพาะเครือข่ายบ้านที่เชื่อถือได้. Private อาจอนุญาตการค้นหา/แชร์อุปกรณ์ในเครือข่าย. ดำเนินการต่อหรือไม่?", "Network Profile Warning", [System.Windows.MessageBoxButton]::YesNo, [System.Windows.MessageBoxImage]::Warning)
    if ($confirm -ne [System.Windows.MessageBoxResult]::Yes) { return }
    try {
        if ($script:BoostBackupLoadError) { throw "อ่าน Snapshot เดิมไม่ได้ จึงระงับการเปลี่ยน network profile" }
        $backupKey = "PROFILE|$($selected.Profile.InterfaceIndex)"
        if (-not $script:BoostBk.ContainsKey($backupKey)) {
            $script:BoostBk[$backupKey] = @{
                InterfaceIndex = [int]$selected.Profile.InterfaceIndex
                Category = [string]$selected.Profile.NetworkCategory
            }
            Save-BoostBk
        }
        Set-NetConnectionProfile -InterfaceIndex $selected.Profile.InterfaceIndex -NetworkCategory Private -ErrorAction Stop
        Update-FreedomSystemDiagnostics
    } catch {
        [FreedomThemedMessageBox]::Show("เปลี่ยน network profile ไม่สำเร็จ: $($_.Exception.Message)", "Freedom Optimizer", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error) | Out-Null
    }
})

# NETWORK ACTIONS
$window.FindName("BtnNetTweak").Add_Click({
    $window.Cursor = [System.Windows.Input.Cursors]::Wait
    try {
        Set-FiveMQoS
    } catch {
        [FreedomThemedMessageBox]::Show("ตั้งค่า FiveM QoS/DSCP ไม่สำเร็จ: $($_.Exception.Message)", "Freedom Optimizer", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error) | Out-Null
    } finally {
        $window.Cursor = [System.Windows.Input.Cursors]::Arrow
    }
})
$window.FindName("BtnNetCheck").Add_Click({
    $window.Cursor = [System.Windows.Input.Cursors]::Wait
    try {
        $interfaceMetrics = @{}
        Get-NetIPInterface -AddressFamily IPv4 -ErrorAction Stop |
            Where-Object { $_.ConnectionState -eq "Connected" } |
            ForEach-Object { $interfaceMetrics[[int]$_.InterfaceIndex] = [int]$_.InterfaceMetric }
        $routeCandidates = Get-NetRoute -DestinationPrefix "0.0.0.0/0" -ErrorAction Stop |
            Where-Object { $_.NextHop -and $_.NextHop -ne "0.0.0.0" -and $interfaceMetrics.ContainsKey([int]$_.InterfaceIndex) } |
            ForEach-Object {
                [pscustomobject]@{
                    Route = $_
                    Metric = [int]$_.RouteMetric + $interfaceMetrics[[int]$_.InterfaceIndex]
                }
            }
        $route = ($routeCandidates | Sort-Object -Property Metric | Select-Object -First 1).Route
        if (-not $route) { throw "ไม่พบ IPv4 default gateway ที่ใช้งานอยู่" }

        $adapter = Get-NetAdapter -InterfaceIndex $route.InterfaceIndex -ErrorAction Stop
        $pingTarget = {
            param([string]$Address)
            $ping = [System.Net.NetworkInformation.Ping]::new()
            $samples = [System.Collections.Generic.List[long]]::new()
            try {
                for ($i = 0; $i -lt 8; $i++) {
                    $reply = $ping.Send($Address, 1000)
                    if ($reply.Status -eq [System.Net.NetworkInformation.IPStatus]::Success) {
                        $samples.Add([long]$reply.RoundtripTime)
                    }
                }
            } finally {
                $ping.Dispose()
            }
            $average = $null
            $minimum = $null
            $maximum = $null
            $jitter = $null
            if ($samples.Count -gt 0) {
                $average = [math]::Round(($samples | Measure-Object -Average).Average, 1)
                $minimum = ($samples | Measure-Object -Minimum).Minimum
                $maximum = ($samples | Measure-Object -Maximum).Maximum
            }
            if ($samples.Count -gt 1) {
                $jitterSum = 0
                for ($i = 1; $i -lt $samples.Count; $i++) {
                    $jitterSum += [math]::Abs($samples[$i] - $samples[$i - 1])
                }
                $jitter = [math]::Round($jitterSum / ($samples.Count - 1), 1)
            }
            [pscustomobject]@{
                Address = $Address
                Received = $samples.Count
                Lost = 8 - $samples.Count
                AverageMs = $average
                MinimumMs = $minimum
                MaximumMs = $maximum
                JitterMs = $jitter
            }
        }

        $gatewayResult = & $pingTarget $route.NextHop
        $internetResult = & $pingTarget "1.1.1.1"
        $formatPing = {
            param($Result)
            if ($null -eq $Result.AverageMs) { return "ไม่มีการตอบกลับ (สูญหาย $($Result.Lost)/8)" }
            $jitterText = if ($null -eq $Result.JitterMs) { "คำนวณไม่ได้" } else { "$($Result.JitterMs) ms" }
            return "เฉลี่ย $($Result.AverageMs) ms, ต่ำสุด/สูงสุด $($Result.MinimumMs)/$($Result.MaximumMs) ms, jitter โดยประมาณ $jitterText, สูญหาย $($Result.Lost)/8"
        }
        $gatewaySummary = & $formatPing $gatewayResult
        $internetSummary = & $formatPing $internetResult
        $report = @(
            "อะแดปเตอร์: $($adapter.Name) ($($adapter.Status))",
            "ความเร็วลิงก์: $($adapter.LinkSpeed)",
            "Gateway ($($route.NextHop)): $gatewaySummary",
            "Internet (1.1.1.1): $internetSummary",
            "",
            "Jitter คือค่าเฉลี่ยความต่างของ RTT ระหว่างคำตอบที่ได้รับ ใช้ดูเสถียรภาพเบื้องต้นเท่านั้น ผลนี้ไม่ใช่ ping ไปยัง FiveM server; ICMP อาจถูกบล็อก และไม่รับประกันค่า FPS หรือ latency ในเกม"
        )
        [FreedomThemedMessageBox]::Show(($report -join "`n"), "Network Check", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information) | Out-Null
    } catch {
        [FreedomThemedMessageBox]::Show("ตรวจเครือข่ายไม่สำเร็จ: $($_.Exception.Message)", "Freedom Optimizer", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Warning) | Out-Null
    } finally {
        $window.Cursor = [System.Windows.Input.Cursors]::Arrow
    }
})
$window.FindName("BtnNetFlush").Add_Click({
    $result = ipconfig /flushdns 2>&1
    if ($LASTEXITCODE -eq 0) {
        [FreedomThemedMessageBox]::Show("ล้าง DNS cache แล้ว การล้างนี้ไม่ได้ลด ping โดยตรง", "Freedom Optimizer", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information) | Out-Null
    } else {
        [FreedomThemedMessageBox]::Show("ล้าง DNS cache ไม่สำเร็จ:`n$($result -join "`n")", "Freedom Optimizer", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Warning) | Out-Null
    }
})
$window.FindName("BtnNetRestore").Add_Click({
    try {
        Restore-FiveMQoS
    } catch {
        [FreedomThemedMessageBox]::Show("คืนค่า QoS/DSCP ไม่สำเร็จ: $($_.Exception.Message)", "Freedom Optimizer", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error) | Out-Null
    }
})

# POWER / TIMER ACTIONS
$script:PowerPlanBackupPath = Join-Path $env:APPDATA "Freedom\power_plan_backup.xml"

function Save-ActivePowerPlan {
    if (Test-Path -LiteralPath $script:PowerPlanBackupPath) { return }
    $output = powercfg /getactivescheme 2>&1
    if ($LASTEXITCODE -ne 0) { throw "อ่าน Power Plan ปัจจุบันไม่สำเร็จ: $($output -join ' ')" }
    $match = [regex]::Match(($output -join "`n"), '[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
    if (-not $match.Success) { throw "ไม่พบ GUID ของ Power Plan ปัจจุบัน" }
    $backupDir = Split-Path -Parent $script:PowerPlanBackupPath
    if (-not (Test-Path -LiteralPath $backupDir)) {
        New-Item -Path $backupDir -ItemType Directory -Force -ErrorAction Stop | Out-Null
    }
    [pscustomobject]@{ ActiveGuid = $match.Value } | Export-Clixml -LiteralPath $script:PowerPlanBackupPath -ErrorAction Stop
}

function Restore-ActivePowerPlan {
    if (-not (Test-Path -LiteralPath $script:PowerPlanBackupPath)) { return $false }
    $snapshot = Import-Clixml -LiteralPath $script:PowerPlanBackupPath -ErrorAction Stop
    if ($snapshot.ActiveGuid -notmatch '^[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}$') {
        throw "Power Plan Snapshot มี GUID ที่ไม่ถูกต้อง"
    }
    $output = powercfg /setactive $snapshot.ActiveGuid 2>&1
    if ($LASTEXITCODE -ne 0) { throw "คืน Power Plan ไม่สำเร็จ: $($output -join ' ')" }
    Remove-Item -LiteralPath $script:PowerPlanBackupPath -Force -ErrorAction Stop
    return $true
}

function Invoke-FreedomPowerCfg {
    param(
        [Parameter(Mandatory = $true)][string]$Operation,
        [Parameter(ValueFromRemainingArguments = $true)][string[]]$Arguments
    )
    $output = & powercfg $Operation @Arguments 2>&1
    if ($LASTEXITCODE -ne 0) {
        $script:PowerPlanFailures++
        return $false
    }
    return $true
}
$window.FindName("BtnPowerImport").Add_Click({
    Write-Log "Importing & Applying Power Plan 'Freedom'..."
    $script:PowerPlanFailures = 0
    try { Save-ActivePowerPlan } catch {
        [FreedomThemedMessageBox]::Show("บันทึกแผนพลังงานเดิมไม่สำเร็จ จึงไม่เปลี่ยนแผน: $($_.Exception.Message)", "Freedom Optimizer", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Warning) | Out-Null
        return
    }
    
    $allSchemes = powercfg /list 2>&1
    if ($LASTEXITCODE -ne 0) {
        [FreedomThemedMessageBox]::Show("อ่านรายการ Power Plan ไม่สำเร็จ: $($allSchemes -join ' ')", "Freedom Optimizer", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Warning) | Out-Null
        return
    }
    $motemGuid = $null
    
    foreach ($line in ($allSchemes -split "`r?`n")) {
        if ($line -match "Power Scheme GUID:\s+([a-f0-9\-]+)\s+\((.*)\)") {
            $guid = $matches[1]
            $name = $matches[2].Trim()
            if ($name -eq "Freedom") {
                $motemGuid = $guid
                break
            }
        }
    }
    
    if (-not $motemGuid) {
        # Duplicate Balanced to avoid forcing a permanently high CPU minimum on battery.
        foreach ($baseScheme in @("381b4222-f694-41f0-9685-ff5bb260df2e", "8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c")) {
            $dupOut = powercfg /duplicatescheme $baseScheme 2>&1
            if ($LASTEXITCODE -eq 0) {
                $match = [regex]::Match(($dupOut | Out-String), "[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}", [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
                if ($match.Success -and $match.Value -ne $baseScheme) { $motemGuid = $match.Value; break }
            }
        }
    }
    
    if ($motemGuid) {
        Invoke-FreedomPowerCfg /changename $motemGuid "Freedom" "High Performance Custom Power Plan" | Out-Null
        # 1. Hard disk: Turn off hard disk after -> 20 min (1200 sec)
        Invoke-FreedomPowerCfg /setacvalueindex $motemGuid 0012ee47-9041-4b5d-9b77-535fba8b1442 6738e2c4-e8a5-4a42-b16a-e040e769756e 1200 | Out-Null
        Invoke-FreedomPowerCfg /setdcvalueindex $motemGuid 0012ee47-9041-4b5d-9b77-535fba8b1442 6738e2c4-e8a5-4a42-b16a-e040e769756e 1200 | Out-Null
        # 2. Internet Explorer mode: JavaScript Timer Frequency -> Maximum Performance (1)
        Invoke-FreedomPowerCfg /setacvalueindex $motemGuid 02f815b5-a5cf-4c84-bf20-649d1f75d3d8 4c793e7d-a264-42e1-87d3-7a0d2f523ccd 1 | Out-Null
        Invoke-FreedomPowerCfg /setdcvalueindex $motemGuid 02f815b5-a5cf-4c84-bf20-649d1f75d3d8 4c793e7d-a264-42e1-87d3-7a0d2f523ccd 1 | Out-Null
        # 3. Desktop background settings: Slide show -> Available (0)
        Invoke-FreedomPowerCfg /setacvalueindex $motemGuid 0d7dbae2-4294-402a-ba8e-26777e8488cd 309dce9b-bef4-4119-9921-a851fb12f0f4 0 | Out-Null
        Invoke-FreedomPowerCfg /setdcvalueindex $motemGuid 0d7dbae2-4294-402a-ba8e-26777e8488cd 309dce9b-bef4-4119-9921-a851fb12f0f4 0 | Out-Null
        # 4. Wireless Adapter Settings: Power Saving Mode -> Maximum Performance (0)
        Invoke-FreedomPowerCfg /setacvalueindex $motemGuid 19cbb8fa-5279-450e-9fac-8a3d5fedd0c1 12bbebe6-58d6-4636-95bb-3217ef867c1a 0 | Out-Null
        Invoke-FreedomPowerCfg /setdcvalueindex $motemGuid 19cbb8fa-5279-450e-9fac-8a3d5fedd0c1 12bbebe6-58d6-4636-95bb-3217ef867c1a 0 | Out-Null
        # 5. Sleep: Sleep after -> Never (0)
        Invoke-FreedomPowerCfg /setacvalueindex $motemGuid 238c9fa8-0aad-41ed-83f4-97be242c8f20 29f6c1db-86da-48c5-9fdb-f2b67b1f44da 0 | Out-Null
        Invoke-FreedomPowerCfg /setdcvalueindex $motemGuid 238c9fa8-0aad-41ed-83f4-97be242c8f20 29f6c1db-86da-48c5-9fdb-f2b67b1f44da 0 | Out-Null
        # 6. Sleep: Allow wake timers -> Enable (1)
        Invoke-FreedomPowerCfg /setacvalueindex $motemGuid 238c9fa8-0aad-41ed-83f4-97be242c8f20 bd3b718a-0680-4d9d-8ab2-e1d2b4ac806d 1 | Out-Null
        Invoke-FreedomPowerCfg /setdcvalueindex $motemGuid 238c9fa8-0aad-41ed-83f4-97be242c8f20 bd3b718a-0680-4d9d-8ab2-e1d2b4ac806d 1 | Out-Null
        # 7. USB settings: USB selective suspend setting -> Disabled (0)
        Invoke-FreedomPowerCfg /setacvalueindex $motemGuid 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 0 | Out-Null
        Invoke-FreedomPowerCfg /setdcvalueindex $motemGuid 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 0 | Out-Null
        # 8. PCI Express: Link State Power Management -> Off (0)
        Invoke-FreedomPowerCfg /setacvalueindex $motemGuid 501a4d13-42af-4429-9fd1-a8218c268e20 ee12f906-d277-404b-b6da-e5fa1a576df5 0 | Out-Null
        Invoke-FreedomPowerCfg /setdcvalueindex $motemGuid 501a4d13-42af-4429-9fd1-a8218c268e20 ee12f906-d277-404b-b6da-e5fa1a576df5 0 | Out-Null
        # Keep the CPU minimum from the Balanced-derived plan to avoid needless idle power draw.
        
        # 10. Processor power management: System cooling policy -> Active (1)
        Invoke-FreedomPowerCfg /setacvalueindex $motemGuid 54533251-82be-4824-96c1-47b60b740d00 94d3a615-a899-4ac5-ae2b-e4d8f634367f 1 | Out-Null
        Invoke-FreedomPowerCfg /setdcvalueindex $motemGuid 54533251-82be-4824-96c1-47b60b740d00 94d3a615-a899-4ac5-ae2b-e4d8f634367f 1 | Out-Null
        # 11. Processor power management: Maximum processor state -> 100%
        Invoke-FreedomPowerCfg /setacvalueindex $motemGuid 54533251-82be-4824-96c1-47b60b740d00 bc5038f7-23e0-4960-96da-33abaf5935ec 100 | Out-Null
        Invoke-FreedomPowerCfg /setdcvalueindex $motemGuid 54533251-82be-4824-96c1-47b60b740d00 bc5038f7-23e0-4960-96da-33abaf5935ec 100 | Out-Null
        # 12. Display: Turn off display after -> 15 min (900 sec)
        Invoke-FreedomPowerCfg /setacvalueindex $motemGuid 7516b95f-f776-4464-8c53-06167f40cc99 3c0bc021-c8a8-4e07-a973-6b14cbcb2b7e 900 | Out-Null
        Invoke-FreedomPowerCfg /setdcvalueindex $motemGuid 7516b95f-f776-4464-8c53-06167f40cc99 3c0bc021-c8a8-4e07-a973-6b14cbcb2b7e 900 | Out-Null
        # 13. Multimedia: When sharing media -> Prevent idling to sleep (1)
        Invoke-FreedomPowerCfg /setacvalueindex $motemGuid 9596fb26-9850-41fd-ac3e-f7c3c00afd4b 03680956-93bc-4294-bba6-4e0f09bb717f 1 | Out-Null
        Invoke-FreedomPowerCfg /setdcvalueindex $motemGuid 9596fb26-9850-41fd-ac3e-f7c3c00afd4b 03680956-93bc-4294-bba6-4e0f09bb717f 1 | Out-Null
        # 14. Multimedia: Video playback quality bias -> Video playback performance bias (1)
        Invoke-FreedomPowerCfg /setacvalueindex $motemGuid 9596fb26-9850-41fd-ac3e-f7c3c00afd4b 10778347-1370-4ee0-8bbd-33bdacaade49 1 | Out-Null
        Invoke-FreedomPowerCfg /setdcvalueindex $motemGuid 9596fb26-9850-41fd-ac3e-f7c3c00afd4b 10778347-1370-4ee0-8bbd-33bdacaade49 1 | Out-Null
        # 15. Multimedia: When playing video -> Optimize video quality (0)
        Invoke-FreedomPowerCfg /setacvalueindex $motemGuid 9596fb26-9850-41fd-ac3e-f7c3c00afd4b 34c7b99f-9a6d-4b3c-8dc7-b6693b78cef4 0 | Out-Null
        Invoke-FreedomPowerCfg /setdcvalueindex $motemGuid 9596fb26-9850-41fd-ac3e-f7c3c00afd4b 34c7b99f-9a6d-4b3c-8dc7-b6693b78cef4 0 | Out-Null
        # 16. AMD Power Slider -> Best performance (3)
        Invoke-FreedomPowerCfg /setacvalueindex $motemGuid c763b4ec-0e50-4b6b-9bed-2b92a6ee884e 7ec1751b-60ed-4588-afb5-9819d3d77d90 3 | Out-Null
        Invoke-FreedomPowerCfg /setdcvalueindex $motemGuid c763b4ec-0e50-4b6b-9bed-2b92a6ee884e 7ec1751b-60ed-4588-afb5-9819d3d77d90 3 | Out-Null
        # Preserve the Balanced-derived CPU minimum and unexposed processor defaults.

        $setActiveOutput = powercfg /setactive $motemGuid 2>&1
        if ($LASTEXITCODE -ne 0) {
            [FreedomThemedMessageBox]::Show("ตั้งค่าแผน Freedom ไม่สำเร็จ: $($setActiveOutput -join ' ')", "Freedom Optimizer", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Warning) | Out-Null
            return
        }
        $activeOutput = powercfg /getactivescheme 2>&1
        $activeMatch = [regex]::Match(($activeOutput -join "`n"), '[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
        if ($LASTEXITCODE -ne 0 -or -not $activeMatch.Success -or $activeMatch.Value -ne $motemGuid) {
            [FreedomThemedMessageBox]::Show("Powercfg ไม่ยืนยันว่าแผน Freedom ถูกเปิดใช้งาน กรุณาตรวจแผนพลังงานด้วยตนเอง", "Freedom Optimizer", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Warning) | Out-Null
            return
        }
        Write-Log "Power Plan 'Freedom' applied and activated."
        Update-Status
        if ($script:PowerPlanFailures -gt 0) {
            [FreedomThemedMessageBox]::Show("เปิดแผน Freedom แล้ว แต่ Windows ปฏิเสธค่าบางรายการ ($($script:PowerPlanFailures) รายการ) ซึ่งอาจไม่รองรับบนอุปกรณ์นี้", "Freedom Optimizer", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Warning) | Out-Null
        } else {
            [FreedomThemedMessageBox]::Show("เปิดใช้งานแผน Power Plan 'Freedom' แล้ว", "Freedom Optimizer", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information) | Out-Null
        }
    } else {
        [FreedomThemedMessageBox]::Show("สร้างแผน Power Plan 'Freedom' ไม่สำเร็จ`n`nตรวจสอบว่ารันเป็นผู้ดูแลระบบ และคำสั่ง powercfg ใช้งานได้", "Freedom Optimizer", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Warning) | Out-Null
    }
})
$window.FindName("BtnTimerEnable").Add_Click({
    Write-Log "Installing FiveM-only Timer Resolution Service..."
    try {
    $csCode = @'
using System;
using System.Runtime.InteropServices;
using System.ServiceProcess;
using System.ComponentModel;
using System.Configuration.Install;
using System.Collections.Generic;
using System.Reflection;
using System.IO;
using System.Management;
using System.Threading;
using System.Diagnostics;
[assembly: AssemblyVersion("2.1")]
[assembly: AssemblyProduct("Set Timer Resolution Service")]
namespace WindowsService
{
    class WindowsService : ServiceBase
    {
        public WindowsService()
        {
            this.ServiceName = "STR";
            this.EventLog.Log = "Application";
            this.CanStop = true;
            this.CanHandlePowerEvent = false;
            this.CanHandleSessionChangeEvent = false;
            this.CanPauseAndContinue = false;
            this.CanShutdown = false;
        }
        static void Main()
        {
            ServiceBase.Run(new WindowsService());
        }
        protected override void OnStart(string[] args)
        {
            base.OnStart(args);
            ReadProcessList();
            NtQueryTimerResolution(out this.MininumResolution, out this.MaximumResolution, out this.DefaultResolution);
            if(null != this.EventLog)
                try { this.EventLog.WriteEntry(String.Format("Minimum={0}; Maximum={1}; Default={2}; Processes='{3}'", this.MininumResolution, this.MaximumResolution, this.DefaultResolution, null != this.ProcessesNames ? String.Join("','", this.ProcessesNames) : "")); }
                catch {}
            if(null == this.ProcessesNames)
            {
                SetMaximumResolution();
                return;
            }
            if(0 == this.ProcessesNames.Count)
            {
                return;
            }
            this.ProcessStartDelegate = new OnProcessStart(this.ProcessStarted);
            try
            {
                String query = String.Format("SELECT * FROM __InstanceCreationEvent WITHIN 0.5 WHERE (TargetInstance isa \"Win32_Process\") AND ((TargetInstance.Name=\"{0}\") OR (TargetInstance.Name LIKE \"FiveM_b%_GTAProcess.exe\"))", String.Join("\" OR TargetInstance.Name=\"", this.ProcessesNames));
                this.startWatch = new ManagementEventWatcher(query);
                this.startWatch.EventArrived += this.startWatch_EventArrived;
                this.startWatch.Start();
                foreach(Process process in Process.GetProcesses())
                {
                    if(IsTargetProcess(process.ProcessName))
                        this.ProcessStartDelegate.BeginInvoke((UInt32)process.Id, null, null);
                }
            }
            catch(Exception ee)
            {
                if(null != this.EventLog)
                    try { this.EventLog.WriteEntry(ee.ToString(), EventLogEntryType.Error); }
                    catch {}
            }
        }
        protected override void OnStop()
        {
            if(null != this.startWatch)
            {
                this.startWatch.Stop();
            }

            base.OnStop();
        }
        ManagementEventWatcher startWatch;
        void startWatch_EventArrived(object sender, EventArrivedEventArgs e) 
        {
            try
            {
                ManagementBaseObject process = (ManagementBaseObject)e.NewEvent.Properties["TargetInstance"].Value;
                UInt32 processId = (UInt32)process.Properties["ProcessId"].Value;
                this.ProcessStartDelegate.BeginInvoke(processId, null, null);
            } 
            catch(Exception ee) 
            {
                if(null != this.EventLog)
                    try { this.EventLog.WriteEntry(ee.ToString(), EventLogEntryType.Warning); }
                    catch {}

            }
        }
        [DllImport("kernel32.dll", SetLastError=true)]
        static extern Int32 WaitForSingleObject(IntPtr Handle, Int32 Milliseconds);
        [DllImport("kernel32.dll", SetLastError=true)]
        static extern IntPtr OpenProcess(UInt32 DesiredAccess, Int32 InheritHandle, UInt32 ProcessId);
        [DllImport("kernel32.dll", SetLastError=true)]
        static extern Int32 CloseHandle(IntPtr Handle);
        const UInt32 SYNCHRONIZE = 0x00100000;
        delegate void OnProcessStart(UInt32 processId);
        OnProcessStart ProcessStartDelegate = null;
        bool IsTargetProcess(String processName)
        {
            String name = processName.ToLowerInvariant() + ".exe";
            return this.ProcessesNames.Contains(name) ||
                (name.StartsWith("fivem_b", StringComparison.Ordinal) && name.EndsWith("_gtaprocess.exe", StringComparison.Ordinal));
        }
        void ProcessStarted(UInt32 processId)
        {
            SetMaximumResolution();
            IntPtr processHandle = IntPtr.Zero;
            try
            {
                processHandle = OpenProcess(SYNCHRONIZE, 0, processId);
                if(processHandle != IntPtr.Zero)
                    WaitForSingleObject(processHandle, -1);
            } 
            catch(Exception ee) 
            {
                if(null != this.EventLog)
                    try { this.EventLog.WriteEntry(ee.ToString(), EventLogEntryType.Warning); }
                    catch {}
            }
            finally
            {
                if(processHandle != IntPtr.Zero)
                    CloseHandle(processHandle); 
            }
            SetDefaultResolution();
        }
        List<String> ProcessesNames = null;
        void ReadProcessList()
        {
            String iniFilePath = Assembly.GetExecutingAssembly().Location + ".ini";
            if(File.Exists(iniFilePath))
            {
                this.ProcessesNames = new List<String>();
                String[] iniFileLines = File.ReadAllLines(iniFilePath);
                foreach(var line in iniFileLines)
                {
                    String[] names = line.Split(new char[] {',', ' ', ';'} , StringSplitOptions.RemoveEmptyEntries);
                    foreach(var name in names)
                    {
                        String lwr_name = name.ToLower();
                        if(!lwr_name.EndsWith(".exe"))
                            lwr_name += ".exe";
                        if(!this.ProcessesNames.Contains(lwr_name))
                            this.ProcessesNames.Add(lwr_name);
                    }
                }
            }
        }
        [DllImport("ntdll.dll", SetLastError=true)]
        static extern int NtSetTimerResolution(uint DesiredResolution, bool SetResolution, out uint CurrentResolution);
        [DllImport("ntdll.dll", SetLastError=true)]
        static extern int NtQueryTimerResolution(out uint MinimumResolution, out uint MaximumResolution, out uint ActualResolution);
        uint DefaultResolution = 0;
        uint MininumResolution = 0;
        uint MaximumResolution = 0;
        long processCounter = 0;
        void SetMaximumResolution()
        {
            long counter = Interlocked.Increment(ref this.processCounter);
            if(counter <= 1)
            {
                uint actual = 0;
                NtSetTimerResolution(this.MininumResolution, true, out actual);
                if(null != this.EventLog)
                    try { this.EventLog.WriteEntry(String.Format("Actual resolution = {0}", actual)); }
                    catch {}
            }
        }
        void SetDefaultResolution()
        {
            long counter = Interlocked.Decrement(ref this.processCounter);
            if(counter == 0)
            {
                uint actual = 0;
                NtSetTimerResolution(this.MininumResolution, false, out actual);
                if(null != this.EventLog)
                    try { this.EventLog.WriteEntry(String.Format("Actual resolution = {0}", actual)); }
                    catch {}
            }
        }
    }
    [RunInstaller(true)]
    public class WindowsServiceInstaller : Installer
    {
        public WindowsServiceInstaller()
        {
            ServiceProcessInstaller serviceProcessInstaller = 
                               new ServiceProcessInstaller();
            ServiceInstaller serviceInstaller = new ServiceInstaller();
            serviceProcessInstaller.Account = ServiceAccount.LocalSystem;
            serviceProcessInstaller.Username = null;
            serviceProcessInstaller.Password = null;
            serviceInstaller.DisplayName = "Set Timer Resolution Service";
            serviceInstaller.StartType = ServiceStartMode.Automatic;
            serviceInstaller.ServiceName = "STR";
            this.Installers.Add(serviceProcessInstaller);
            this.Installers.Add(serviceInstaller);
        }
    }
}
'@

    $csPath = "C:\Windows\SetTimerResolutionService.cs"
    $exePath = "C:\Windows\SetTimerResolutionService.exe"
    
    $legacyService = Get-Service -Name "Set Timer Resolution Service" -ErrorAction SilentlyContinue
    if ($legacyService) {
        Stop-Service -Name "Set Timer Resolution Service" -Force -ErrorAction SilentlyContinue
        sc.exe delete "Set Timer Resolution Service" | Out-Null
        Start-Sleep -Milliseconds 500
    }
    if (Get-Service -Name "STR" -ErrorAction SilentlyContinue) {
        Stop-Service -Name "STR" -Force -ErrorAction Stop
        sc.exe delete "STR" | Out-Null
        Start-Sleep -Milliseconds 800
    }
    [System.IO.File]::WriteAllText("$exePath.ini", "FiveM.exe,FiveM_GTAProcess.exe,FiveM_b3258_GTAProcess.exe")
    [System.IO.File]::WriteAllText($csPath, $csCode)
    $compiler = Join-Path $env:WINDIR "Microsoft.NET\Framework64\v4.0.30319\csc.exe"
    if (-not (Test-Path -LiteralPath $compiler)) { $compiler = Join-Path $env:WINDIR "Microsoft.NET\Framework\v4.0.30319\csc.exe" }
    if (-not (Test-Path -LiteralPath $compiler)) { throw "ไม่พบ C# compiler สำหรับติดตั้ง Timer Service" }
    $compile = Start-Process -FilePath $compiler -ArgumentList @("/nologo", "-r:System.ServiceProcess.dll", "-r:System.Configuration.Install.dll", "-r:System.Management.dll", "-out:$exePath", $csPath) -Wait -PassThru -WindowStyle Hidden
    if ($compile.ExitCode -ne 0) { throw "คอมไพล์ Timer Service ไม่สำเร็จ (exit code $($compile.ExitCode))" }
    Remove-Item $csPath -ErrorAction SilentlyContinue | Out-Null
    
    New-Service -Name "STR" -DisplayName "Set Timer Resolution Service" -BinaryPathName $exePath -ErrorAction Stop | Out-Null
    Set-Service -Name "STR" -StartupType Automatic -ErrorAction Stop
    Set-Service -Name "STR" -Status Running -ErrorAction Stop
    
    Write-Log "Set Timer Resolution Service installed and started for FiveM."
    Update-Status
    $svcChk = Get-Service -Name "STR" -ErrorAction SilentlyContinue
    if ($null -eq $svcChk -or $svcChk.Status -ne 'Running') {
        [FreedomThemedMessageBox]::Show("ติดตั้งหรือเริ่ม Set Timer Resolution Service ไม่สำเร็จ`n`nตรวจสอบว่ามี .NET Framework 4.x และไม่มีโปรแกรมแอนตี้ไวรัสบล็อกการสร้างไฟล์ใน C:\Windows", "Freedom Optimizer", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Warning) | Out-Null
        return
    }
    [FreedomThemedMessageBox]::Show("Timer Service ทำงานแล้ว โดยจะขอค่าความละเอียดสูงสุดที่ Windows รองรับเฉพาะขณะ FiveM ทำงาน ผลจริงขึ้นกับ Windows และอุปกรณ์", "Freedom Optimizer", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information) | Out-Null
    } catch {
        [FreedomThemedMessageBox]::Show("ติดตั้ง Timer Service ไม่สำเร็จ: $($_.Exception.Message)", "Freedom Optimizer", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Warning) | Out-Null
    }
})
$window.FindName("BtnTimerDisable").Add_Click({
    Write-Log "Removing FiveM-only Timer Resolution Service..."
    try {
        foreach ($serviceName in @("STR", "Set Timer Resolution Service")) {
            $service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
            if ($service) {
                if ($service.Status -ne 'Stopped') { Stop-Service -Name $serviceName -Force -ErrorAction Stop }
                $deleteOutput = sc.exe delete $serviceName 2>&1
                if ($LASTEXITCODE -ne 0 -and $LASTEXITCODE -ne 1060) {
                    throw "ลบบริการ $serviceName ไม่สำเร็จ: $($deleteOutput -join ' ')"
                }
            }
        }
        foreach ($file in @("C:\Windows\SetTimerResolutionService.exe", "C:\Windows\SetTimerResolutionService.exe.ini")) {
            if (Test-Path -LiteralPath $file) { Remove-Item -LiteralPath $file -Force -ErrorAction Stop }
        }
        Write-Log "FiveM-only Timer Resolution Service removed."
        Update-Status
        [FreedomThemedMessageBox]::Show("ลบ Timer Service เรียบร้อยแล้ว Windows จะใช้ Timer Resolution ตามคำขอของระบบ/แอปพลิเคชัน", "Freedom Optimizer", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information) | Out-Null
    } catch {
        [FreedomThemedMessageBox]::Show("ลบ Timer Service ไม่สำเร็จ: $($_.Exception.Message)", "Freedom Optimizer", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Warning) | Out-Null
    }
})
# ========================================================
# TOOLS / CLEANER ACTIONS (UNIFIED)
# ========================================================
function Get-DirSize([string]$p) {
    try {
        $m = Get-ChildItem -LiteralPath $p -Recurse -Force -File -ErrorAction Stop | Measure-Object -Property Length -Sum
        if ($m.Sum) { return [int64]$m.Sum } else { return 0 }
    } catch { return $null }
}

function Test-FreedomFileInUseError {
    param([System.Exception]$Exception)
    while ($null -ne $Exception) {
        $nativeCode = $Exception.HResult -band 0xFFFF
        if ($nativeCode -in @(32, 33) -or $Exception.Message -match "being used by another process|used by another process|sharing violation") {
            return $true
        }
        $Exception = $Exception.InnerException
    }
    return $false
}

# 1. READ-ONLY RAM STATUS
$window.FindName("BtnFreeRam").Add_Click({
    try {
        $memory = Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction Stop
        $freeGb = [math]::Round($memory.FreePhysicalMemory / 1MB, 1)
        $totalGb = [math]::Round($memory.TotalVisibleMemorySize / 1MB, 1)
        [FreedomThemedMessageBox]::Show("RAM ว่าง: $freeGb GB จากทั้งหมด $totalGb GB`n`nไม่ได้ล้าง Standby cache หรือ Working Set เพราะ Windows ใช้หน่วยความจำเหล่านั้นซ้ำได้ และการบังคับล้างอาจเพิ่มอาการกระตุก โดยเฉพาะขณะเล่นเกม", "Freedom Optimizer", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information) | Out-Null
    } catch {
        [FreedomThemedMessageBox]::Show("ตรวจสอบ RAM ไม่สำเร็จ: $($_.Exception.Message)", "Freedom Optimizer", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Warning) | Out-Null
    }
})

# 2. DEEP CLEAN (JUNK FILES) - UNIFIED
$window.FindName("BtnDeepClean").Add_Click({
    $window.Cursor = [System.Windows.Input.Cursors]::Wait
    try {
        $targets = @(
            $env:TEMP,
            "$env:WINDIR\Temp",
            "$env:LOCALAPPDATA\CrashDumps",
            "$env:WINDIR\Minidump",
            "$env:LOCALAPPDATA\Microsoft\Windows\WER",
            "$env:ProgramData\Microsoft\Windows\WER\ReportQueue",
            "$env:ProgramData\Microsoft\Windows\WER\ReportArchive",
            "$env:LOCALAPPDATA\Microsoft\Windows\INetCache"
        )
        $before = 0
        $removedItems = 0
        $skippedItems = 0
        $measurementsComplete = $true
        $cleanupErrors = [System.Collections.Generic.List[string]]::new()
        $cleanupDetails = [System.Collections.Generic.List[string]]::new()
        foreach ($t in $targets) {
            if (Test-Path -LiteralPath $t) {
                $size = Get-DirSize $t
                if ($null -eq $size) { $measurementsComplete = $false } else { $before += $size }
            }
        }

        foreach ($t in $targets) {
            if (-not (Test-Path -LiteralPath $t)) { continue }
            try {
                $items = @(Get-ChildItem -LiteralPath $t -Force -ErrorAction Stop)
                foreach ($item in $items) {
                    try {
                        Remove-Item -LiteralPath $item.FullName -Recurse -Force -ErrorAction Stop
                        $removedItems++
                    } catch {
                        if (Test-FreedomFileInUseError $_.Exception) {
                            $skippedItems++
                            if ($cleanupDetails.Count -lt 100) { $cleanupDetails.Add("ข้ามรายการที่กำลังถูกใช้งาน: $($item.FullName)") }
                        } else {
                            $cleanupErrors.Add("$($item.FullName) : $($_.Exception.Message)")
                            if ($cleanupDetails.Count -lt 100) { $cleanupDetails.Add("ลบไม่สำเร็จ: $($item.FullName) — $($_.Exception.Message)") }
                        }
                    }
                }
            } catch {
                $cleanupErrors.Add("$t : $($_.Exception.Message)")
                if ($cleanupDetails.Count -lt 100) { $cleanupDetails.Add("อ่านโฟลเดอร์ไม่สำเร็จ: $t — $($_.Exception.Message)") }
            }
        }
        # Thumbnail cache
        $thumbnailPath = "$env:LOCALAPPDATA\Microsoft\Windows\Explorer"
        try {
            $thumbnails = @(Get-ChildItem -LiteralPath $thumbnailPath -Filter "thumbcache_*.db" -Force -ErrorAction Stop)
            foreach ($thumbnail in $thumbnails) {
                try {
                    Remove-Item -LiteralPath $thumbnail.FullName -Force -ErrorAction Stop
                    $removedItems++
                } catch {
                    if (Test-FreedomFileInUseError $_.Exception) {
                        $skippedItems++
                        if ($cleanupDetails.Count -lt 100) { $cleanupDetails.Add("ข้าม Thumbnail ที่กำลังถูกใช้งาน: $($thumbnail.FullName)") }
                    } else {
                        $cleanupErrors.Add("$($thumbnail.FullName) : $($_.Exception.Message)")
                        if ($cleanupDetails.Count -lt 100) { $cleanupDetails.Add("ลบ Thumbnail ไม่สำเร็จ: $($thumbnail.FullName) — $($_.Exception.Message)") }
                    }
                }
            }
        } catch {
            if (Test-Path -LiteralPath $thumbnailPath) {
                $cleanupErrors.Add("$thumbnailPath : $($_.Exception.Message)")
                if ($cleanupDetails.Count -lt 100) { $cleanupDetails.Add("อ่าน Thumbnail cache ไม่สำเร็จ: $thumbnailPath — $($_.Exception.Message)") }
            }
        }
        $dnsOutput = ipconfig /flushdns 2>&1
        if ($LASTEXITCODE -ne 0) {
            $cleanupErrors.Add("DNS cache : $($dnsOutput -join ' ')")
            if ($cleanupDetails.Count -lt 100) { $cleanupDetails.Add("ล้าง DNS cache ไม่สำเร็จ: $($dnsOutput -join ' ')") }
        }

        $after = 0
        foreach ($t in $targets) {
            if (Test-Path -LiteralPath $t) {
                $size = Get-DirSize $t
                if ($null -eq $size) { $measurementsComplete = $false } else { $after += $size }
            }
        }
        if ($measurementsComplete) {
            $freed = [math]::Round(($before - $after) / 1MB, 1)
            if ($freed -lt 0) { $freed = 0 }
            $freedText = "พื้นที่ว่างเพิ่มประมาณ: $freed MB"
        } else {
            $freedText = "ไม่สามารถคำนวณพื้นที่ที่คืนได้ครบ"
        }
        $summary = @(
            "ลบรายการสำเร็จ: $removedItems",
            "ข้ามรายการที่ระบบกำลังใช้งาน: $skippedItems",
            $freedText,
            "ถังขยะไม่ได้ถูกลบ"
        ) -join "`n"
        if ($cleanupDetails.Count -gt 0) {
            if ($cleanupErrors.Count + $skippedItems -gt $cleanupDetails.Count) {
                $cleanupDetails.Add("แสดงรายละเอียดสูงสุด 100 รายการ")
            }
            $detailText = $cleanupDetails -join "`n"
        } else {
            $detailText = ""
        }
        if ($cleanupErrors.Count -gt 0 -or $skippedItems -gt 0) {
            $message = "ทำความสะอาดเสร็จบางส่วน ไฟล์ที่ Windows หรือแอปกำลังใช้งานจะถูกข้ามไว้"
            $kind = "Warning"
        } else {
            $message = "ทำความสะอาดไฟล์ชั่วคราวและล้าง DNS cache เรียบร้อย"
            $kind = "Success"
        }
        Show-FreedomNotice -Title "Deep Clean" -Message $message -Summary $summary -Details $detailText -Kind $kind
    } catch {
        Show-FreedomNotice -Title "Deep Clean" -Message "เกิดข้อผิดพลาดระหว่างทำความสะอาด" -Summary $_.Exception.Message -Kind Error
    } finally {
        $window.Cursor = [System.Windows.Input.Cursors]::Arrow
    }
})

# 3. CLEAN FIVEM CACHE
$window.FindName("BtnFiveMCache").Add_Click({
    $running = @(Get-Process -Name "FiveM","FiveM_GTAProcess","FiveM_b*_GTAProcess" -ErrorAction SilentlyContinue)
    if ($running.Count -gt 0) {
        [FreedomThemedMessageBox]::Show("ปิด FiveM ให้หมดก่อนล้าง Cache", "Freedom Optimizer", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Warning) | Out-Null
        return
    }

    $paths = @(
        "$env:LOCALAPPDATA\FiveM\FiveM.app\data\cache",
        "$env:LOCALAPPDATA\FiveM\FiveM.app\data\server-cache",
        "$env:LOCALAPPDATA\FiveM\FiveM.app\data\server-cache-priv"
    )
    $removed = 0
    $errors = [System.Collections.Generic.List[string]]::new()
    foreach ($path in $paths) {
        if (-not (Test-Path -LiteralPath $path)) { continue }
        try {
            $items = @(Get-ChildItem -LiteralPath $path -Force -ErrorAction Stop)
            foreach ($item in $items) {
                Remove-Item -LiteralPath $item.FullName -Recurse -Force -ErrorAction Stop
                $removed++
            }
        } catch {
            $errors.Add("$path : $($_.Exception.Message)")
        }
    }
    if ($errors.Count -gt 0) {
        [FreedomThemedMessageBox]::Show("ล้าง Cache ได้บางส่วน ($removed รายการ)`n`n" + ($errors -join "`n"), "Freedom Optimizer", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Warning) | Out-Null
    } elseif ($removed -eq 0) {
        [FreedomThemedMessageBox]::Show("ไม่พบ Cache ที่ต้องล้าง หรือโฟลเดอร์ว่างอยู่แล้ว", "Freedom Optimizer", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information) | Out-Null
    } else {
        [FreedomThemedMessageBox]::Show("ล้าง Cache สำเร็จ $removed รายการ เกมอาจโหลดช้าหรือกระตุกชั่วคราวเมื่อเข้าเซิร์ฟเวอร์ครั้งถัดไป", "Freedom Optimizer", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information) | Out-Null
    }
})

# 4. OPTIMIZE GPU SHADERS
$window.FindName("BtnGpu").Add_Click({
    $running = @(Get-Process -Name "FiveM","FiveM_GTAProcess","FiveM_b*_GTAProcess" -ErrorAction SilentlyContinue)
    if ($running.Count -gt 0) {
        [FreedomThemedMessageBox]::Show("ปิด FiveM ให้หมดก่อนล้าง GPU Shader Cache", "Freedom Optimizer", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Warning) | Out-Null
        return
    }
    $confirm = [FreedomThemedMessageBox]::Show("การลบ Shader Cache ไม่ได้เพิ่ม FPS โดยตรง และอาจทำให้เกิดอาการกระตุกชั่วคราวระหว่างสร้างแคชใหม่ ต้องการดำเนินการต่อหรือไม่?", "Freedom Optimizer", [System.Windows.MessageBoxButton]::YesNo, [System.Windows.MessageBoxImage]::Warning)
    if ($confirm -ne [System.Windows.MessageBoxResult]::Yes) { return }

    $paths = @(
        "$env:LOCALAPPDATA\D3DSCache",
        "$env:LOCALAPPDATA\NVIDIA\DXCache",
        "$env:LOCALAPPDATA\NVIDIA\GLCache",
        "$env:LOCALAPPDATA\AMD\DxCache"
    )
    $removed = 0
    $errors = [System.Collections.Generic.List[string]]::new()
    foreach ($path in $paths) {
        if (-not (Test-Path -LiteralPath $path)) { continue }
        try {
            $items = @(Get-ChildItem -LiteralPath $path -Force -ErrorAction Stop)
            foreach ($item in $items) {
                Remove-Item -LiteralPath $item.FullName -Recurse -Force -ErrorAction Stop
                $removed++
            }
        } catch {
            $errors.Add("$path : $($_.Exception.Message)")
        }
    }
    if ($errors.Count -gt 0) {
        [FreedomThemedMessageBox]::Show("ล้าง Shader Cache ได้บางส่วน ($removed รายการ)`n`n" + ($errors -join "`n"), "Freedom Optimizer", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Warning) | Out-Null
    } elseif ($removed -eq 0) {
        [FreedomThemedMessageBox]::Show("ไม่พบ Shader Cache ที่ต้องล้าง หรือโฟลเดอร์ว่างอยู่แล้ว", "Freedom Optimizer", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information) | Out-Null
    } else {
        [FreedomThemedMessageBox]::Show("ล้าง Shader Cache สำเร็จ $removed รายการ เมื่อเปิดเกมครั้งแรกอาจมีอาการกระตุกขณะสร้างแคชใหม่", "Freedom Optimizer", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information) | Out-Null
    }
})

# RESTORE ACTIONS
$window.FindName("BtnRestoreAll").Add_Click({
    $confirm = [FreedomThemedMessageBox]::Show("การดำเนินการจะคืน CPU priority จาก Snapshot (หรือใช้ค่า Windows มาตรฐานเมื่อไม่มี Snapshot), Power Plan, Input/QoS, Game Mode, MMCSS/TCP, Network Adapter และ Timer Service ของ Freedom เฉพาะรายการที่โปรแกรมมีข้อมูลสำรอง`n`nการปรับ BCD ต้องใช้ปุ่ม Restore แยกในหน้า Advanced`n`nดำเนินการต่อหรือไม่?", "Freedom Optimizer", [System.Windows.MessageBoxButton]::YesNo, [System.Windows.MessageBoxImage]::Warning)
    if ($confirm -ne [System.Windows.MessageBoxResult]::Yes) { return }
    Write-Log "Resetting supported Freedom settings..."
    try {
        [void](Restore-Win32Priority)
        if (Test-Path -LiteralPath $script:InputBackupPath) { Restore-InputSettings }
        if (Test-Path -LiteralPath $script:QosBackupPath) { Restore-QosSnapshot }
        if (Test-Path -LiteralPath $script:PowerPlanBackupPath) { [void](Restore-ActivePowerPlan) }

        foreach ($serviceName in @("STR", "Set Timer Resolution Service")) {
            $service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
            if ($service) {
                if ($service.Status -ne 'Stopped') { Stop-Service -Name $serviceName -Force -ErrorAction Stop }
                $deleteOutput = sc.exe delete $serviceName 2>&1
                if ($LASTEXITCODE -ne 0 -and $LASTEXITCODE -ne 1060) {
                    throw "ลบบริการ $serviceName ไม่สำเร็จ: $($deleteOutput -join ' ')"
                }
            }
        }
        foreach ($file in @("C:\Windows\SetTimerResolutionService.exe", "C:\Windows\SetTimerResolutionService.exe.ini")) {
            if (Test-Path -LiteralPath $file) { Remove-Item -LiteralPath $file -Force -ErrorAction Stop }
        }
    } catch {
        [FreedomThemedMessageBox]::Show("คืนค่าระบบได้ไม่ครบ: $($_.Exception.Message)`n`nข้อมูลสำรองที่ยังเหลือจะไม่ถูกลบ กรุณาแก้สิทธิ์/สาเหตุแล้วลองอีกครั้ง", "Freedom Optimizer", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Warning) | Out-Null
        return
    }

    Write-Log "Supported Freedom settings reset."
    Update-Status
    [FreedomThemedMessageBox]::Show("คืนค่ารายการที่รองรับเรียบร้อยแล้ว หากมีการเปลี่ยนค่าอื่นด้วยตนเองให้คืนค่าจากเมนูเฉพาะของรายการนั้น`n`nการเปลี่ยนรายละเอียดภายในแผน Freedom ที่สร้างไว้จะไม่ถูกลบ ต้องรีสตาร์ทเครื่องเพื่อให้บางค่ามีผล", "Freedom Optimizer", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information) | Out-Null
})
$window.FindName("BtnRestorePoint").Add_Click({
    Write-Log "Creating System Restore Point..."
    try {
        Enable-ComputerRestore -Drive "C:\" -ErrorAction SilentlyContinue
        # -WarningAction Stop: Windows only WARNS (no error) when a restore point was already made in the last 24h
        Checkpoint-Computer -Description "Freedom Backup" -RestorePointType "MODIFY_SETTINGS" -ErrorAction Stop -WarningAction Stop
        Write-Log "System Restore Point Created Successfully."
        [FreedomThemedMessageBox]::Show("สร้าง Restore Point สำเร็จ", "Freedom Optimizer", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information) | Out-Null
    } catch {
        Write-Log "Failed to create Restore Point. Ensure System Restore is enabled."
        [FreedomThemedMessageBox]::Show("สร้าง Restore Point ไม่สำเร็จ`n`n$($_.Exception.Message)`n`n(Windows สร้างได้ 1 ครั้งต่อ 24 ชั่วโมง และต้องเปิด System Restore ไว้)", "Freedom Optimizer", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Warning) | Out-Null
    }
})

# Load Images if they exist
$scriptDir = $PSScriptRoot
if ([string]::IsNullOrEmpty($scriptDir) -and $MyInvocation.MyCommand.Path) {
    try { $scriptDir = $(if ($MyInvocation.MyCommand.Path) { Split-Path -Parent $MyInvocation.MyCommand.Path } else { [System.AppDomain]::CurrentDomain.BaseDirectory }) } catch {}
}
if ([string]::IsNullOrEmpty($scriptDir) -and $PSCommandPath) {
    try { $scriptDir = Split-Path -Parent $PSCommandPath } catch {}
}
if ([string]::IsNullOrEmpty($scriptDir)) {
    $scriptDir = [System.AppDomain]::CurrentDomain.BaseDirectory
}
if ([string]::IsNullOrEmpty($scriptDir)) {
    $scriptDir = [System.IO.Directory]::GetCurrentDirectory()
}
if ($globalAvatarBrush) { $window.FindName("ProfileImage").Fill = $globalAvatarBrush }



# ========================================================
# BOOST TAB (added)
# ========================================================
$script:BoostDir  = Join-Path $env:APPDATA "Freedom"
$script:BoostFile = Join-Path $script:BoostDir "boost_backup.xml"
$script:BoostBk = @{}
$script:BoostBackupLoadError = $null
try {
    if (Test-Path -LiteralPath $script:BoostFile) {
        $loadedBackup = Import-Clixml -LiteralPath $script:BoostFile -ErrorAction Stop
        if ($loadedBackup -isnot [hashtable]) { throw "รูปแบบ Snapshot ไม่ถูกต้อง" }
        $script:BoostBk = $loadedBackup
    }
} catch {
    $script:BoostBackupLoadError = $_.Exception.Message
}

function Save-BoostBk {
    if (-not (Test-Path -LiteralPath $script:BoostDir)) {
        New-Item -Path $script:BoostDir -ItemType Directory -Force -ErrorAction Stop | Out-Null
    }
    $script:BoostBk | Export-Clixml -LiteralPath $script:BoostFile -ErrorAction Stop
}

function Show-BoostMsg([string]$msg) {
    [FreedomThemedMessageBox]::Show($msg, "Freedom Optimizer", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information) | Out-Null
}

# ตั้งค่า Registry พร้อมสำรองค่าเดิม (สำรองครั้งแรกครั้งเดียว)
function Set-BoostReg {
    param([string]$Path, [string]$Name, $Value, [string]$Type = "DWord")
    if ($script:BoostBackupLoadError) {
        throw "อ่าน Snapshot เดิมไม่ได้ จึงระงับการปรับค่าเพื่อป้องกันการเขียนทับข้อมูล: $($script:BoostBackupLoadError)"
    }
    $key = "REG|$Path|$Name"
    if (-not $script:BoostBk.ContainsKey($key)) {
        $regValueExists = $false
        if (Test-Path -LiteralPath $Path) {
            $regKey = Get-Item -LiteralPath $Path -ErrorAction Stop
            if ($regKey.GetValueNames() -contains $Name) {
                $regValueExists = $true
                $script:BoostBk[$key] = @{ Exists = $true; Value = $regKey.GetValue($Name); Type = $regKey.GetValueKind($Name).ToString() }
            }
        }
        if (-not $regValueExists) {
            $script:BoostBk[$key] = @{ Exists = $false; Value = $null; Type = $Type }
        }
        Save-BoostBk
    }
    if (-not (Test-Path -LiteralPath $Path)) { New-Item -Path $Path -Force -ErrorAction Stop | Out-Null }
    Set-ItemProperty -Path $Path -Name $Name -Value $Value -Type $Type -Force -ErrorAction Stop
}

function Set-FreedomGameModeSettings {
    if ($script:BoostBackupLoadError) {
        throw "อ่าน Snapshot เดิมไม่ได้ จึงระงับการปรับค่าเพื่อป้องกันการเขียนทับข้อมูล: $($script:BoostBackupLoadError)"
    }
    Set-BoostReg "HKCU:\Software\Microsoft\GameBar" "AutoGameModeEnabled" 1
    Set-BoostReg "HKCU:\System\GameConfigStore" "GameDVR_Enabled" 0
    Set-BoostReg "HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR" "AppCaptureEnabled" 0
    Save-BoostBk
}

function Set-FreedomVisualSettings {
    if ($script:BoostBackupLoadError) {
        throw "อ่าน Snapshot เดิมไม่ได้ จึงระงับการปรับค่าเพื่อป้องกันการเขียนทับข้อมูล: $($script:BoostBackupLoadError)"
    }
    Set-BoostReg "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" "EnableTransparency" 0
    Set-BoostReg "HKCU:\Control Panel\Desktop\WindowMetrics" "MinAnimate" "0" "String"
    Set-BoostReg "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "TaskbarAnimations" 0
    Set-BoostReg "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "ListviewShadow" 0
    Save-BoostBk
}

function Get-FreedomPlanGuid {
    foreach ($line in ((powercfg /list) -split "`r?`n")) {
        if ($line -match "GUID:\s+([a-f0-9\-]{36})\s+\((.*)\)" -and $matches[2].Trim() -eq "Freedom") { return $matches[1] }
    }
    return $null
}

function Set-FreedomPowerPlanTuning {
    Save-ActivePowerPlan
    $planGuid = $null
    $schemes = powercfg /list 2>&1
    if ($LASTEXITCODE -ne 0) { throw "อ่าน Power Plan ไม่สำเร็จ: $($schemes -join ' ')" }
    foreach ($line in ($schemes -split "`r?`n")) {
        if ($line -match "GUID:\s+([a-f0-9\-]{36})\s+\((.*)\)" -and $matches[2].Trim() -eq "Freedom Game Optimized") {
            $planGuid = $matches[1]
            break
        }
    }
    if (-not $planGuid) {
        $active = powercfg /getactivescheme 2>&1
        if ($LASTEXITCODE -ne 0) { throw "อ่าน Power Plan ที่ใช้งานอยู่ไม่สำเร็จ: $($active -join ' ')" }
        $activeMatch = [regex]::Match(($active -join "`n"), '[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
        if (-not $activeMatch.Success) { throw "ไม่พบ GUID ของ Power Plan ที่ใช้งานอยู่" }
        $duplicate = powercfg /duplicatescheme $activeMatch.Value 2>&1
        if ($LASTEXITCODE -ne 0) { throw "สร้าง Power Plan สำหรับเกมไม่สำเร็จ: $($duplicate -join ' ')" }
        $newMatch = [regex]::Match(($duplicate | Out-String), '[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
        if (-not $newMatch.Success) { throw "Powercfg ไม่คืน GUID ของแผนใหม่" }
        $planGuid = $newMatch.Value
        $rename = powercfg /changename $planGuid "Freedom Game Optimized" "Freedom gaming power settings" 2>&1
        if ($LASTEXITCODE -ne 0) { throw "ตั้งชื่อ Power Plan ไม่สำเร็จ: $($rename -join ' ')" }
    }

    $script:PowerPlanFailures = 0
    $subgroup = "54533251-82be-4824-96c1-47b60b740d00"
    $settings = @(
        @{ Guid = "0cc5b647-c1df-4637-891a-dec35c318583"; Value = "100" },
        @{ Guid = "be337238-0d82-4146-a960-4f3749d470c7"; Value = "2" },
        @{ Guid = "4b92d758-5a24-4851-a470-815d78aee119"; Value = "100" },
        @{ Guid = "7b224883-b3cc-4d79-819f-8374152cbe7c"; Value = "100" }
    )
    foreach ($setting in $settings) {
        Invoke-FreedomPowerCfg /setacvalueindex $planGuid $subgroup $setting.Guid $setting.Value | Out-Null
    }
    if ($script:PowerPlanFailures -gt 0) { throw "Windows rejected $($script:PowerPlanFailures) Core Parking/Boost/Idle setting(s)" }
    $activeOutput = powercfg /setactive $planGuid 2>&1
    if ($LASTEXITCODE -ne 0) { throw "เปิดใช้ Power Plan ไม่สำเร็จ: $($activeOutput -join ' ')" }
    $verify = powercfg /getactivescheme 2>&1
    if ($LASTEXITCODE -ne 0 -or $verify -notmatch [regex]::Escape($planGuid)) { throw "ตรวจยืนยัน Power Plan ที่เปิดใช้ไม่สำเร็จ" }
}

function Get-FreedomActivePhysicalAdapter {
    $interfaceMetrics = @{}
    Get-NetIPInterface -AddressFamily IPv4 -ErrorAction Stop |
        Where-Object { $_.ConnectionState -eq "Connected" } |
        ForEach-Object { $interfaceMetrics[[int]$_.InterfaceIndex] = [int]$_.InterfaceMetric }
    $rankedRoutes = @(Get-NetRoute -DestinationPrefix "0.0.0.0/0" -ErrorAction Stop |
        Where-Object { $_.NextHop -and $_.NextHop -ne "0.0.0.0" -and $interfaceMetrics.ContainsKey([int]$_.InterfaceIndex) } |
        ForEach-Object {
            [pscustomobject]@{
                Route = $_
                Metric = [int]$_.RouteMetric + $interfaceMetrics[[int]$_.InterfaceIndex]
            }
        } |
        Sort-Object -Property Metric)
    if ($rankedRoutes.Count -eq 0) { throw "ไม่พบ IPv4 default route ที่เชื่อมต่ออยู่" }
    $bestMetric = $rankedRoutes[0].Metric
    $bestInterfaces = @($rankedRoutes | Where-Object { $_.Metric -eq $bestMetric } | ForEach-Object { [int]$_.Route.InterfaceIndex } | Sort-Object -Unique)
    if ($bestInterfaces.Count -gt 1) { throw "มีหลาย default route ที่มี priority เท่ากัน จึงไม่ปรับ NIC เพื่อหลีกเลี่ยงการเลือก interface ผิด" }
    $adapter = Get-NetAdapter -InterfaceIndex $rankedRoutes[0].Route.InterfaceIndex -ErrorAction Stop
    if ($null -eq $adapter -or $adapter.Status -ne "Up") { throw "ไม่พบ network adapter ที่ active สำหรับ default route" }
    if (-not $adapter.HardwareInterface -or $adapter.Name -match "(?i)VPN|TAP|TUN|WireGuard|Virtual|Hyper-V|VMware|VirtualBox|WAN Miniport" -or $adapter.InterfaceDescription -match "(?i)VPN|TAP|TUN|WireGuard|Virtual|Hyper-V|VMware|VirtualBox|WAN Miniport") {
        throw "default route ใช้ VPN/TAP/virtual adapter ($($adapter.Name)); เพื่อความปลอดภัยไม่ได้ปรับ NIC ใด"
    }
    return $adapter
}

function Set-FreedomAdapterDisplayOption {
    param(
        [Parameter(Mandatory = $true)]$Adapter,
        [Parameter(Mandatory = $true)]$Properties,
        [Parameter(Mandatory = $true)][string]$DisplayNamePattern,
        [Parameter(Mandatory = $true)][string]$ValuePattern,
        [Parameter(Mandatory = $true)][string]$Label,
        [Parameter(Mandatory = $true)][AllowEmptyCollection()][System.Collections.Generic.List[string]]$Applied,
        [Parameter(Mandatory = $true)][AllowEmptyCollection()][System.Collections.Generic.List[string]]$Skipped
    )
    $matchedProperties = @($Properties | Where-Object { $_.DisplayName -match $DisplayNamePattern })
    if ($matchedProperties.Count -eq 0) { $Skipped.Add("$Label (driver option unavailable)"); return }
    foreach ($property in $matchedProperties) {
        if ([string]::IsNullOrWhiteSpace([string]$property.RegistryKeyword)) {
            $Skipped.Add("$($property.DisplayName) (registry keyword unavailable)")
            continue
        }
        $validValues = @($property.ValidDisplayValues)
        $targetDisplay = $validValues | Where-Object { [string]$_ -match $ValuePattern } | Select-Object -First 1
        $targetRegistry = $null
        if ($null -eq $targetDisplay) {
            $targetRegistry = @($property.ValidRegistryValues) | Where-Object { [string]$_ -match $ValuePattern } | Select-Object -First 1
        }
        if ($null -eq $targetDisplay -and $null -eq $targetRegistry) {
            $Skipped.Add("$($property.DisplayName) (requested value unsupported)")
            continue
        }
        $backupKey = "NETADV|$($Adapter.InterfaceGuid)|$($property.RegistryKeyword)"
        if (-not $script:BoostBk.ContainsKey($backupKey)) {
            $script:BoostBk[$backupKey] = @{
                InterfaceGuid = [string]$Adapter.InterfaceGuid
                RegistryKeyword = [string]$property.RegistryKeyword
                RegistryValue = @($property.RegistryValue)
                DisplayName = [string]$property.DisplayName
            }
            Save-BoostBk
        }
        try {
            if ($null -ne $targetDisplay) {
                Set-NetAdapterAdvancedProperty -Name $Adapter.Name -RegistryKeyword $property.RegistryKeyword -DisplayValue $targetDisplay -NoRestart -ErrorAction Stop
                $Applied.Add("$($property.DisplayName)=$targetDisplay")
            } else {
                Set-NetAdapterAdvancedProperty -Name $Adapter.Name -RegistryKeyword $property.RegistryKeyword -RegistryValue $targetRegistry -NoRestart -ErrorAction Stop
                $Applied.Add("$($property.DisplayName)=$targetRegistry")
            }
        } catch {
            $Skipped.Add("$($property.DisplayName) (driver rejected value: $($_.Exception.Message))")
        }
    }
}

function Set-FreedomAdapterSettings {
    param([Parameter(Mandatory = $true)]$Adapter)
    $applied = [System.Collections.Generic.List[string]]::new()
    $skipped = [System.Collections.Generic.List[string]]::new()
    $guid = [string]$Adapter.InterfaceGuid

    $pmKey = "NETPM|$guid"
    if (-not $script:BoostBk.ContainsKey($pmKey)) {
        $pm = Get-NetAdapterPowerManagement -Name $Adapter.Name -ErrorAction Stop
        $pmValues = @{}
        foreach ($name in @("ArpOffload", "D0PacketCoalescing", "DeviceSleepOnDisconnect", "NSOffload", "RsnRekeyOffload", "SelectiveSuspend", "WakeOnMagicPacket", "WakeOnPattern")) {
            $property = $pm.PSObject.Properties[$name]
            if ($property -and $null -ne $property.Value) { $pmValues[$name] = [string]$property.Value }
        }
        $script:BoostBk[$pmKey] = @{ InterfaceGuid = $guid; Values = $pmValues }
        Save-BoostBk
    }
    Disable-NetAdapterPowerManagement -Name $Adapter.Name -NoRestart -ErrorAction Stop
    $applied.Add("Adapter power management disabled")

    $rssKey = "NETRSS|$guid"
    try {
        $rss = Get-NetAdapterRss -Name $Adapter.Name -ErrorAction Stop
        if ($null -eq $rss) { throw "RSS state unavailable" }
        if (-not $script:BoostBk.ContainsKey($rssKey)) {
            $script:BoostBk[$rssKey] = @{ InterfaceGuid = $guid; Enabled = [bool]$rss.Enabled }
            Save-BoostBk
        }
        Enable-NetAdapterRss -Name $Adapter.Name -NoRestart -ErrorAction Stop
        $applied.Add("RSS enabled")
    } catch {
        $skipped.Add("RSS (unsupported or driver rejected change: $($_.Exception.Message))")
    }

    $rscKey = "NETRSC|$guid"
    try {
        $rsc = Get-NetAdapterRsc -Name $Adapter.Name -ErrorAction Stop
        if ($null -eq $rsc) { throw "RSC state unavailable" }
        if (-not $script:BoostBk.ContainsKey($rscKey)) {
            $script:BoostBk[$rscKey] = @{
                InterfaceGuid = $guid
                IPv4Enabled = [bool]$rsc.IPv4Enabled
                IPv6Enabled = [bool]$rsc.IPv6Enabled
            }
            Save-BoostBk
        }
        Disable-NetAdapterRsc -Name $Adapter.Name -IPv4 -IPv6 -NoRestart -ErrorAction Stop
        $applied.Add("RSC IPv4/IPv6 disabled")
    } catch {
        $skipped.Add("RSC (unsupported or driver rejected change: $($_.Exception.Message))")
    }

    $lsoKey = "NETLSO|$guid"
    try {
        $lso = Get-NetAdapterLso -Name $Adapter.Name -ErrorAction Stop
        if ($null -eq $lso) { throw "LSO state unavailable" }
        if (-not $script:BoostBk.ContainsKey($lsoKey)) {
            $script:BoostBk[$lsoKey] = @{
                InterfaceGuid = $guid
                IPv4Enabled = [bool]$lso.IPv4Enabled
                IPv6Enabled = [bool]$lso.IPv6Enabled
            }
            Save-BoostBk
        }
        Disable-NetAdapterLso -Name $Adapter.Name -IPv4 -IPv6 -NoRestart -ErrorAction Stop
        $applied.Add("LSO IPv4/IPv6 disabled")
    } catch {
        $skipped.Add("LSO (unsupported or driver rejected change: $($_.Exception.Message))")
    }

    $properties = @(Get-NetAdapterAdvancedProperty -Name $Adapter.Name -AllProperties -ErrorAction Stop)
    $options = @(
        @{ Pattern = '^Interrupt Moderation$'; Value = '^(Disabled|Off)$'; Label = 'Interrupt Moderation' },
        @{ Pattern = '^Receive Buffers$'; Value = '^2048(?:\s+bytes?)?$'; Label = 'Receive Buffers 2048' },
        @{ Pattern = '^Transmit Buffers$'; Value = '^2048(?:\s+bytes?)?$'; Label = 'Transmit Buffers 2048' },
        @{ Pattern = '^(Energy.?Efficient Ethernet|EEE)(?:\s.*)?$'; Value = '^(Disabled|Off)$'; Label = 'EEE disabled' },
        @{ Pattern = '^Flow Control$'; Value = '^(Disabled|Off)$'; Label = 'Flow Control disabled' }
    )
    foreach ($option in $options) {
        Set-FreedomAdapterDisplayOption -Adapter $Adapter -Properties $properties -DisplayNamePattern $option.Pattern -ValuePattern $option.Value -Label $option.Label -Applied $applied -Skipped $skipped
    }
    return [pscustomobject]@{ Applied = @($applied); Skipped = @($skipped) }
}

function Set-FreedomCoreSettings {
    if ($script:BoostBackupLoadError) {
        throw "อ่าน Snapshot เดิมไม่ได้ จึงระงับการปรับค่าเพื่อป้องกันการเขียนทับข้อมูล: $($script:BoostBackupLoadError)"
    }
    $adapter = Get-FreedomActivePhysicalAdapter
    if ([string]$adapter.InterfaceGuid -notmatch '^\{?[a-f0-9-]{36}\}?$') { throw "Active adapter มี InterfaceGuid ไม่ถูกต้อง" }
    $base = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile"
    Set-BoostReg $base "SystemResponsiveness" 10
    Set-BoostReg $base "NetworkThrottlingIndex" ([uint32]::MaxValue)
    foreach ($taskName in @("Games", "Low Latency", "Capture", "Pro Audio")) {
        $taskPath = Join-Path (Join-Path $base "Tasks") $taskName
        Set-BoostReg $taskPath "GPU Priority" 8
        Set-BoostReg $taskPath "Priority" 6
        Set-BoostReg $taskPath "Scheduling Category" "High" "String"
        Set-BoostReg $taskPath "SFIO Priority" "High" "String"
    }

    $tcpKey = "NETSH|global"
    if (-not $script:BoostBk.ContainsKey($tcpKey)) {
        $tcpSnapshot = netsh interface tcp dump 2>&1
        if ($LASTEXITCODE -ne 0) { throw "อ่าน TCP global snapshot ไม่สำเร็จ: $($tcpSnapshot -join ' ')" }
        $script:BoostBk[$tcpKey] = @{ Commands = @($tcpSnapshot) }
        Save-BoostBk
    }
    $tcpOutput = netsh interface tcp set global autotuninglevel=normal rss=enabled ecncapability=enabled timestamps=disabled 2>&1
    if ($LASTEXITCODE -ne 0) { throw "ตั้งค่า TCP global ไม่สำเร็จ: $($tcpOutput -join ' ')" }
    $tcpStatus = netsh interface tcp show global 2>&1
    if ($LASTEXITCODE -ne 0) { throw "ตรวจสอบ TCP global หลังตั้งค่าไม่สำเร็จ: $($tcpStatus -join ' ')" }

    $naglePath = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\$($adapter.InterfaceGuid.ToString('B'))"
    Set-BoostReg $naglePath "TcpAckFrequency" 1
    Set-BoostReg $naglePath "TCPNoDelay" 1
    $adapterResult = Set-FreedomAdapterSettings -Adapter $adapter
    $script:LastCoreSettingsSummary = "NIC: $($adapter.Name); applied: $($adapterResult.Applied -join ', '); driver options skipped: $($adapterResult.Skipped -join ', '); TCP chimney offload: unsupported by this Windows netsh version"
    Save-BoostBk
}

function Get-FreedomLatestBcdBackup {
    $directory = Join-Path $script:BoostDir "BCD"
    if (-not (Test-Path -LiteralPath $directory)) { return $null }
    return Get-ChildItem -LiteralPath $directory -Filter "bcd-backup-*.bcd" -File -ErrorAction Stop |
        Sort-Object -Property LastWriteTimeUtc -Descending |
        Select-Object -First 1
}

function Export-FreedomBcdBackup {
    $directory = Join-Path $script:BoostDir "BCD"
    if (-not (Test-Path -LiteralPath $directory)) {
        New-Item -Path $directory -ItemType Directory -Force -ErrorAction Stop | Out-Null
    }
    $path = Join-Path $directory ("bcd-backup-{0}.bcd" -f (Get-Date -Format "yyyyMMdd-HHmmss-fff"))
    $output = bcdedit /export $path 2>&1
    if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $path)) {
        throw "BCD backup export failed: $($output -join ' ')"
    }
    return $path
}

function Get-FreedomBcdCurrentValues {
    $output = bcdedit /enum "{current}" 2>&1
    if ($LASTEXITCODE -ne 0) { throw "อ่าน BCD ปัจจุบันไม่สำเร็จ: $($output -join ' ')" }
    $values = @{}
    foreach ($name in @("useplatformclock", "disabledynamictick", "useplatformtick", "tscsyncpolicy")) {
        $line = $output | Where-Object { $_ -match "^\s*$([regex]::Escape($name))\s+" } | Select-Object -First 1
        $values[$name] = if ($line) { ($line -replace "^\s*$([regex]::Escape($name))\s+", "").Trim() } else { "Not set (Windows default)" }
    }
    return $values
}

function Update-FreedomAdvancedStatus {
    try {
        $values = Get-FreedomBcdCurrentValues
        $window.FindName("TxtBcdStatus").Text = "Current BCD: useplatformclock=$($values.useplatformclock); disabledynamictick=$($values.disabledynamictick); useplatformtick=$($values.useplatformtick); tscsyncpolicy=$($values.tscsyncpolicy)"
        $latest = Get-FreedomLatestBcdBackup
        if ($latest) { $window.FindName("TxtBcdStatus").Text += "`nLatest BCD backup: $($latest.FullName)" }
    } catch {
        $window.FindName("TxtBcdStatus").Text = "อ่านสถานะ BCD ไม่สำเร็จ: $($_.Exception.Message)"
    }
}

function Find-FreedomMsiDevices {
    $list = $window.FindName("LstMsiDevices")
    $list.Items.Clear()
    try {
        $devices = Get-PnpDevice -PresentOnly -ErrorAction Stop |
            Where-Object { $_.Status -eq "OK" -and $_.Class -in @("Display", "Net", "USB", "SCSIAdapter", "HDC", "Storage") }
        $supported = 0
        foreach ($device in $devices) {
            $devicePath = "HKLM:\SYSTEM\CurrentControlSet\Enum\$($device.InstanceId)\Device Parameters\Interrupt Management\MessageSignaledInterruptProperties"
            if (-not (Test-Path -LiteralPath $devicePath)) { continue }
            $key = Get-Item -LiteralPath $devicePath -ErrorAction Stop
            if ($key.GetValueNames() -notcontains "MSISupported") { continue }
            $supported++
            $enabled = [int]$key.GetValue("MSISupported") -eq 1
            [void]$list.Items.Add([pscustomobject]@{
                Display = "$($device.FriendlyName) [$($device.Class)] - MSI $(if ($enabled) { 'ON' } else { 'OFF' })"
                FriendlyName = $device.FriendlyName
                Class = $device.Class
                InstanceId = $device.InstanceId
                RegistryPath = $devicePath
                Enabled = $enabled
            })
        }
        $window.FindName("TxtMsiStatus").Text = "Found $supported present device(s) with an existing MSISupported setting. Only selected devices can be changed."
    } catch {
        $window.FindName("TxtMsiStatus").Text = "Device scan failed: $($_.Exception.Message)"
    }
}

$window.FindName("BtnBcdExport").Add_Click({
    try {
        $path = Export-FreedomBcdBackup
        Update-FreedomAdvancedStatus
        [FreedomThemedMessageBox]::Show("BCD สำรองแล้ว:`n$path", "Freedom Optimizer", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information) | Out-Null
    } catch {
        [FreedomThemedMessageBox]::Show("สำรอง BCD ไม่สำเร็จ: $($_.Exception.Message)", "Freedom Optimizer", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error) | Out-Null
    }
})

$window.FindName("BtnBcdApply").Add_Click({
    $selected = [System.Collections.Generic.List[string]]::new()
    if ($window.FindName("ChkDeletePlatformClock").IsChecked) { $selected.Add("delete useplatformclock") }
    if ($window.FindName("ChkDynamicTick").IsChecked) { $selected.Add("set disabledynamictick yes") }
    if ($window.FindName("ChkPlatformTick").IsChecked) { $selected.Add("set useplatformtick yes") }
    if ($window.FindName("ChkTscSyncEnhanced").IsChecked) { $selected.Add("set tscsyncpolicy enhanced") }
    if ($selected.Count -ne 1) {
        [FreedomThemedMessageBox]::Show("เลือกค่า BCD เพียง 1 รายการต่อการทดสอบ เพื่อให้เปรียบเทียบ A/B และคืนค่าได้ตรงจุด", "Freedom Optimizer", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Warning) | Out-Null
        return
    }
    try {
        $currentBcd = Get-FreedomBcdCurrentValues
    } catch {
        [FreedomThemedMessageBox]::Show("อ่านค่า BCD ปัจจุบันไม่สำเร็จ จึงไม่ปรับค่า: $($_.Exception.Message)", "Freedom Optimizer", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error) | Out-Null
        return
    }
    $alreadyConfigured = $false
    if ($window.FindName("ChkDeletePlatformClock").IsChecked -and $currentBcd.useplatformclock -like "Not set*") { $alreadyConfigured = $true }
    if ($window.FindName("ChkDynamicTick").IsChecked -and $currentBcd.disabledynamictick -eq "Yes") { $alreadyConfigured = $true }
    if ($window.FindName("ChkPlatformTick").IsChecked -and $currentBcd.useplatformtick -eq "Yes") { $alreadyConfigured = $true }
    if ($window.FindName("ChkTscSyncEnhanced").IsChecked -and $currentBcd.tscsyncpolicy -eq "Enhanced") { $alreadyConfigured = $true }
    if ($alreadyConfigured) {
        [FreedomThemedMessageBox]::Show("ค่าที่เลือกตั้งอยู่แล้วใน BCD ปัจจุบัน ไม่มีการเปลี่ยนแปลง", "Freedom Optimizer", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information) | Out-Null
        return
    }
    $confirm = [FreedomThemedMessageBox]::Show("ก่อนปรับจะ Export BCD backup อัตโนมัติ ค่าเหล่านี้มีผลต่อการบูตและอาจทำให้ระบบทำงานผิดปกติ ต้องทดสอบทีละค่า และอาจต้องรีสตาร์ต:`n`n$($selected -join "`n")`n`nดำเนินการต่อหรือไม่?", "Advanced BCD Warning", [System.Windows.MessageBoxButton]::YesNo, [System.Windows.MessageBoxImage]::Warning)
    if ($confirm -ne [System.Windows.MessageBoxResult]::Yes) { return }
    try {
        $backupPath = Export-FreedomBcdBackup
        $commands = @()
        if ($window.FindName("ChkDeletePlatformClock").IsChecked) { $commands += ,@("deletevalue", "useplatformclock") }
        if ($window.FindName("ChkDynamicTick").IsChecked) { $commands += ,@("set", "disabledynamictick", "yes") }
        if ($window.FindName("ChkPlatformTick").IsChecked) { $commands += ,@("set", "useplatformtick", "yes") }
        if ($window.FindName("ChkTscSyncEnhanced").IsChecked) { $commands += ,@("set", "tscsyncpolicy", "enhanced") }
        foreach ($command in $commands) {
            $output = & bcdedit @command 2>&1
            if ($LASTEXITCODE -ne 0) { throw "bcdedit $($command -join ' ') failed: $($output -join ' ')" }
        }
        Update-FreedomAdvancedStatus
        [FreedomThemedMessageBox]::Show("ปรับค่า BCD ที่เลือกแล้ว`nBackup: $backupPath`n`nรีสตาร์ตเพื่อให้มีผล และเปลี่ยนทีละค่าเพื่อเปรียบเทียบผล หากมีปัญหาให้ใช้ Restore BCD backup", "Freedom Optimizer", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information) | Out-Null
    } catch {
        [FreedomThemedMessageBox]::Show("ปรับ BCD ไม่สำเร็จหรือได้เพียงบางส่วน: $($_.Exception.Message)`n`nBackup ยังคงถูกเก็บไว้", "Freedom Optimizer", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error) | Out-Null
    }
})

$window.FindName("BtnBcdRestore").Add_Click({
    try {
        $backup = Get-FreedomLatestBcdBackup
        if (-not $backup) { throw "ไม่พบ BCD backup ที่ Export ไว้" }
        $confirm = [FreedomThemedMessageBox]::Show("จะ Restore BCD จาก:`n$($backup.FullName)`n`nการ Restore มีผลต่อการบูต Windows และอาจต้องรีสตาร์ต ดำเนินการต่อหรือไม่?", "Restore BCD Warning", [System.Windows.MessageBoxButton]::YesNo, [System.Windows.MessageBoxImage]::Warning)
        if ($confirm -ne [System.Windows.MessageBoxResult]::Yes) { return }
        $safetyBackup = Export-FreedomBcdBackup
        $output = bcdedit /import $backup.FullName 2>&1
        if ($LASTEXITCODE -ne 0) { throw "bcdedit /import failed: $($output -join ' ')" }
        Update-FreedomAdvancedStatus
        [FreedomThemedMessageBox]::Show("Restore BCD สำเร็จ รีสตาร์ต Windows เพื่อใช้ค่าที่คืนแล้ว`nBackup ก่อน Restore: $safetyBackup", "Freedom Optimizer", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information) | Out-Null
    } catch {
        [FreedomThemedMessageBox]::Show("Restore BCD ไม่สำเร็จ: $($_.Exception.Message)", "Freedom Optimizer", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error) | Out-Null
    }
})

$window.FindName("BtnMsiRefresh").Add_Click({ Find-FreedomMsiDevices })
$window.FindName("BtnMsiEnable").Add_Click({
    $selected = @($window.FindName("LstMsiDevices").SelectedItems)
    if ($selected.Count -eq 0) {
        [FreedomThemedMessageBox]::Show("เลือกอุปกรณ์ที่ต้องการก่อนเปิด MSI Mode", "Freedom Optimizer", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Warning) | Out-Null
        return
    }
    $names = ($selected | ForEach-Object { $_.FriendlyName }) -join "`n"
    $confirm = [FreedomThemedMessageBox]::Show("จะเปิด MSI Mode (MSISupported=1) เฉพาะอุปกรณ์ที่เลือก:`n`n$names`n`nการมีค่า MSISupported ไม่รับประกันว่าไดรเวอร์รองรับอย่างเสถียร อาจทำให้อุปกรณ์ทำงานผิดปกติ ต้องการดำเนินการต่อหรือไม่?", "MSI Mode Warning", [System.Windows.MessageBoxButton]::YesNo, [System.Windows.MessageBoxImage]::Warning)
    if ($confirm -ne [System.Windows.MessageBoxResult]::Yes) { return }
    try {
        foreach ($device in $selected) {
            Set-BoostReg $device.RegistryPath "MSISupported" 1
        }
        Save-BoostBk
        Find-FreedomMsiDevices
        [FreedomThemedMessageBox]::Show("ตั้งค่า MSI Mode สำหรับอุปกรณ์ที่เลือกแล้ว แนะนำให้รีสตาร์ต และ Restore ได้จากหน้า Boost หากเกิดปัญหา", "Freedom Optimizer", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information) | Out-Null
    } catch {
        [FreedomThemedMessageBox]::Show("เปิด MSI Mode ไม่สำเร็จหรือได้เพียงบางส่วน: $($_.Exception.Message)", "Freedom Optimizer", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error) | Out-Null
        Find-FreedomMsiDevices
    }
})

$window.FindName("BtnBoostApply").Add_Click({
    $window.Cursor = [System.Windows.Input.Cursors]::Wait
    try {
        Set-FreedomGameModeSettings
        Show-BoostMsg "เปิด Windows Game Mode และปิด Game DVR แล้ว ค่าเดิมถูกสำรองไว้สำหรับ Revert`n`nการเปลี่ยนแปลงนี้อาจไม่เพิ่ม FPS ในทุกเครื่อง"
    } catch {
        Show-BoostMsg "ปรับ Game Mode ไม่สำเร็จ: $($_.Exception.Message)"
    } finally {
        $window.Cursor = [System.Windows.Input.Cursors]::Arrow
    }
})
$window.FindName("BtnBoostRevert").Add_Click({
    $window.Cursor = [System.Windows.Input.Cursors]::Wait
    try {
        $remaining = @{}
        $restoreErrors = [System.Collections.Generic.List[string]]::new()
        if ($script:BoostBackupLoadError) { throw "อ่าน Snapshot เดิมไม่ได้ จึงไม่สามารถคืนค่าได้อย่างปลอดภัย: $($script:BoostBackupLoadError)" }
        foreach ($key in @($script:BoostBk.Keys)) {
            $e = $script:BoostBk[$key]
            try {
                if ($key.StartsWith("REG|")) {
                    $parts = $key.Split("|")
                    if ($parts.Count -ne 3) { throw "Snapshot registry key มีรูปแบบไม่ถูกต้อง" }
                    $path = $parts[1]; $name = $parts[2]
                    if ($e.Exists) {
                        if (-not (Test-Path -LiteralPath $path)) { New-Item -Path $path -Force -ErrorAction Stop | Out-Null }
                        Set-ItemProperty -Path $path -Name $name -Value $e.Value -Type $e.Type -Force -ErrorAction Stop
                    } elseif (Test-Path -LiteralPath $path) {
                        $regKey = Get-Item -LiteralPath $path -ErrorAction Stop
                        if ($regKey.GetValueNames() -contains $name) {
                            Remove-ItemProperty -Path $path -Name $name -ErrorAction Stop
                        }
                    }
                } elseif ($key.StartsWith("NETADV|")) {
                    $adapter = Get-NetAdapter -IncludeHidden -ErrorAction Stop | Where-Object { [string]$_.InterfaceGuid -eq [string]$e.InterfaceGuid } | Select-Object -First 1
                    if (-not $adapter) { throw "ไม่พบ adapter สำหรับคืนค่า $($e.DisplayName)" }
                    Set-NetAdapterAdvancedProperty -Name $adapter.Name -RegistryKeyword $e.RegistryKeyword -RegistryValue $e.RegistryValue -NoRestart -ErrorAction Stop
                } elseif ($key.StartsWith("NETRSC|")) {
                    $adapter = Get-NetAdapter -IncludeHidden -ErrorAction Stop | Where-Object { [string]$_.InterfaceGuid -eq [string]$e.InterfaceGuid } | Select-Object -First 1
                    if (-not $adapter) { throw "ไม่พบ adapter สำหรับคืนค่า RSC" }
                    Set-NetAdapterRsc -Name $adapter.Name -IPv4Enabled ([bool]$e.IPv4Enabled) -IPv6Enabled ([bool]$e.IPv6Enabled) -NoRestart -ErrorAction Stop
                } elseif ($key.StartsWith("NETLSO|")) {
                    $adapter = Get-NetAdapter -IncludeHidden -ErrorAction Stop | Where-Object { [string]$_.InterfaceGuid -eq [string]$e.InterfaceGuid } | Select-Object -First 1
                    if (-not $adapter) { throw "ไม่พบ adapter สำหรับคืนค่า LSO" }
                    if ($e.IPv4Enabled -and $e.IPv6Enabled) {
                        Enable-NetAdapterLso -Name $adapter.Name -IPv4 -IPv6 -NoRestart -ErrorAction Stop
                    } elseif ($e.IPv4Enabled) {
                        Enable-NetAdapterLso -Name $adapter.Name -IPv4 -NoRestart -ErrorAction Stop
                    } elseif ($e.IPv6Enabled) {
                        Enable-NetAdapterLso -Name $adapter.Name -IPv6 -NoRestart -ErrorAction Stop
                    } else {
                        Disable-NetAdapterLso -Name $adapter.Name -IPv4 -IPv6 -NoRestart -ErrorAction Stop
                    }
                } elseif ($key.StartsWith("NETRSS|")) {
                    $adapter = Get-NetAdapter -IncludeHidden -ErrorAction Stop | Where-Object { [string]$_.InterfaceGuid -eq [string]$e.InterfaceGuid } | Select-Object -First 1
                    if (-not $adapter) { throw "ไม่พบ adapter สำหรับคืนค่า RSS" }
                    if ($e.Enabled) {
                        Enable-NetAdapterRss -Name $adapter.Name -NoRestart -ErrorAction Stop
                    } else {
                        Disable-NetAdapterRss -Name $adapter.Name -NoRestart -ErrorAction Stop
                    }
                } elseif ($key.StartsWith("NETPM|")) {
                    if ($e.InterfaceGuid) {
                        $adapter = Get-NetAdapter -IncludeHidden -ErrorAction Stop | Where-Object { [string]$_.InterfaceGuid -eq [string]$e.InterfaceGuid } | Select-Object -First 1
                    } else {
                        $adapter = Get-NetAdapter -Name $key.Substring(6) -IncludeHidden -ErrorAction Stop | Select-Object -First 1
                    }
                    if (-not $adapter) { throw "ไม่พบ adapter สำหรับคืนค่า Power Management" }
                    $hasSavedValues = $false
                    $hasLegacyValue = $false
                    $savedValues = $null
                    $legacyValue = $null
                    if ($e -is [System.Collections.IDictionary]) {
                        $hasSavedValues = $e.Contains("Values")
                        $hasLegacyValue = $e.Contains("Value")
                        if ($hasSavedValues) { $savedValues = $e["Values"] }
                        if ($hasLegacyValue) { $legacyValue = $e["Value"] }
                    } else {
                        $hasSavedValues = $null -ne $e.PSObject.Properties["Values"]
                        $hasLegacyValue = $null -ne $e.PSObject.Properties["Value"]
                        if ($hasSavedValues) { $savedValues = $e.Values }
                        if ($hasLegacyValue) { $legacyValue = $e.Value }
                    }
                    if ($hasSavedValues -and $savedValues) {
                        $pmArguments = @{}
                        foreach ($name in $savedValues.Keys) {
                            if ($savedValues[$name] -in @("Enabled", "Disabled")) { $pmArguments[$name] = $savedValues[$name] }
                        }
                        if ($pmArguments.Count -gt 0) {
                            Set-NetAdapterPowerManagement -Name $adapter.Name @pmArguments -NoRestart -ErrorAction Stop
                        }
                    } elseif ($hasLegacyValue) {
                        if ($legacyValue) {
                            Enable-NetAdapterPowerManagement -Name $adapter.Name -NoRestart -ErrorAction Stop
                        } else {
                            Disable-NetAdapterPowerManagement -Name $adapter.Name -NoRestart -ErrorAction Stop
                        }
                    }
                } elseif ($key.StartsWith("TASK|")) {
                    $task = Get-ScheduledTask -TaskPath $e.TaskPath -TaskName $e.TaskName -ErrorAction Stop
                    if ($e.Enabled) {
                        Enable-ScheduledTask -InputObject $task -ErrorAction Stop | Out-Null
                    } else {
                        Disable-ScheduledTask -InputObject $task -ErrorAction Stop | Out-Null
                    }
                } elseif ($key.StartsWith("PROFILE|")) {
                    $profile = Get-NetConnectionProfile -InterfaceIndex $e.InterfaceIndex -ErrorAction Stop | Select-Object -First 1
                    if (-not $profile) { throw "ไม่พบ network profile สำหรับ interface $($e.InterfaceIndex)" }
                    Set-NetConnectionProfile -InterfaceIndex $e.InterfaceIndex -NetworkCategory $e.Category -ErrorAction Stop
                } elseif ($key -eq "MMAGENT|MemoryCompression") {
                    if ($e.Enabled) {
                        Enable-MMAgent -MemoryCompression -ErrorAction Stop
                    } else {
                        Disable-MMAgent -MemoryCompression -ErrorAction Stop
                    }
                } elseif ($key -eq "NETSH|global") {
                    if (-not $e.Commands) { throw "TCP global snapshot is empty" }
                    $dumpPath = Join-Path $env:TEMP "Freedom-netsh-restore-$PID.txt"
                    try {
                        Set-Content -LiteralPath $dumpPath -Value @($e.Commands) -Encoding ASCII -ErrorAction Stop
                        $output = netsh exec $dumpPath 2>&1
                        if ($LASTEXITCODE -ne 0) { throw "netsh restore failed: $($output -join ' ')" }
                    } finally {
                        if (Test-Path -LiteralPath $dumpPath) { Remove-Item -LiteralPath $dumpPath -Force -ErrorAction Stop }
                    }
                } elseif ($key -eq "BCD|disabledynamictick") {
                    if ($e.Exists -and $e.Value -match '^(yes|no)$') {
                        $output = bcdedit /set disabledynamictick $e.Value 2>&1
                    } else {
                        $output = bcdedit /deletevalue disabledynamictick 2>&1
                    }
                    if ($LASTEXITCODE -ne 0) { throw "bcdedit failed: $($output -join ' ')" }
                } elseif ($key -eq "PLAN|active") {
                    if ($e.Value) {
                        $output = powercfg /setactive $e.Value 2>&1
                        if ($LASTEXITCODE -ne 0) { throw "powercfg failed: $($output -join ' ')" }
                    }
                }
            } catch {
                $remaining[$key] = $e
                $restoreErrors.Add("$key : $($_.Exception.Message)")
            }
        }
        $script:BoostBk = $remaining
        if ($restoreErrors.Count -gt 0) {
            Save-BoostBk
            Show-BoostMsg ("คืนค่า Boost ได้บางส่วน รายการที่ยังคืนไม่ได้ถูกเก็บ Snapshot ไว้ให้ลองอีกครั้ง:`n`n" + ($restoreErrors -join "`n"))
        } else {
            if (Test-Path $script:BoostFile) { Remove-Item $script:BoostFile -Force -ErrorAction Stop }
            Show-BoostMsg "คืนค่า Boost เรียบร้อยแล้ว"
        }
    } catch {
        Show-BoostMsg "เกิดข้อผิดพลาด: $($_.Exception.Message)"
    } finally {
        $window.Cursor = [System.Windows.Input.Cursors]::Arrow
    }
})

$window.FindName("BtnKillBg").Add_Click({
    try {
        $names = @("OneDrive","Teams","ms-teams","Skype","YourPhone","PhoneExperienceHost","GoogleUpdate","AdobeUpdateService","AdobeIPCBroker","CCXProcess","Creative Cloud","Widgets","GameBar","GameBarFTServer")
        $found = @()
        foreach ($n in $names) { $found += @(Get-Process -Name $n -ErrorAction SilentlyContinue) }
        $svc = @("DiagTrack","SysMain","WSearch","MapsBroker","WerSvc")
        $svcRun = @($svc | Where-Object { (Get-Service -Name $_ -ErrorAction SilentlyContinue).Status -eq 'Running' })
        if ($found.Count -eq 0 -and $svcRun.Count -eq 0) { Show-BoostMsg "ไม่พบโปรแกรมเบื้องหลังที่อยู่ในรายการ"; return }
        $list = (($found | ForEach-Object { $_.ProcessName } | Sort-Object -Unique) -join ", ")
        $slist = ($svcRun -join ", ")
        $msg = "จะปิดโปรแกรม: $list`nและหยุดเซอร์วิสชั่วคราว (จนรีสตาร์ท): $slist`n`nต้องการดำเนินการต่อหรือไม่?"
        $r = [FreedomThemedMessageBox]::Show($msg, "Freedom Optimizer", [System.Windows.MessageBoxButton]::YesNo, [System.Windows.MessageBoxImage]::Question)
        if ($r -ne [System.Windows.MessageBoxResult]::Yes) { return }
        $stoppedProcesses = 0
        $stoppedServices = 0
        $stopErrors = [System.Collections.Generic.List[string]]::new()
        foreach ($p in $found) {
            try {
                Stop-Process -Id $p.Id -Force -ErrorAction Stop
                $stoppedProcesses++
            } catch {
                $stopErrors.Add("$($p.ProcessName) : $($_.Exception.Message)")
            }
        }
        foreach ($service in $svcRun) {
            try {
                Stop-Service -Name $service -Force -ErrorAction Stop
                $stoppedServices++
            } catch {
                $stopErrors.Add("$service : $($_.Exception.Message)")
            }
        }
        if ($stopErrors.Count -gt 0) {
            [FreedomThemedMessageBox]::Show("หยุดโปรแกรมได้บางส่วน (โปรแกรม $stoppedProcesses รายการ, Service $stoppedServices รายการ)`n`n" + ($stopErrors -join "`n"), "Freedom Optimizer", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Warning) | Out-Null
        } else {
            Show-BoostMsg "หยุดโปรแกรม $stoppedProcesses รายการและ Service $stoppedServices รายการแล้ว (Service จะกลับมาทำงานเองเมื่อรีสตาร์ทเครื่อง)"
        }
    } catch {
        Show-BoostMsg "เกิดข้อผิดพลาด: $($_.Exception.Message)"
    }
})

$window.FindName("BtnFlushNet").Add_Click({
    try {
        ipconfig /flushdns | Out-Null
        if ($LASTEXITCODE -ne 0) { throw "ipconfig /flushdns ล้มเหลว (exit code $LASTEXITCODE)" }
        Show-BoostMsg "ล้าง DNS cache แล้ว (ไม่ได้ลด ping โดยตรง)"
    } catch {
        Show-BoostMsg "เกิดข้อผิดพลาด: $($_.Exception.Message)"
    }
})

# Window Controls
$window.FindName("BtnMinimize").Add_Click({ $window.WindowState = 'Minimized' })
$window.FindName("BtnClose").Add_Click({ $window.Close() })
$window.FindName("TitleBar").Add_MouseLeftButtonDown({ $window.DragMove() })

# Show Window
$window.ShowDialog() | Out-Null
