// Levels:
// Menu
// Intro
// BrianLab
// ...
// Surface
// Finale

state("vertigo") {}

startup {
  Assembly.Load(File.ReadAllBytes("Components/asl-help"))
      .CreateInstance("Unity");

  vars.Helper.AlertLoadless();

  dynamic[,] settingDefs = {
    {
      "startAtOrigins",
      "Start at Origins instead of the cabin intro level",
      false,
    },
    {
      "useInGameTime",
      "Use in-game time",
      false,
    },
    {
      "resetWithGameTimer",
      "Reset when game timer resets instead of when visiting the main menu",
      false,
    },
  };
  vars.Helper.Settings.CreateCustom(settingDefs, 1, 3, 2);
}

init {
  vars.Helper.TryLoad = (Func<dynamic, bool>)(mono => {
    vars.Helper["gameTimerDisablerCount"] =
        mono.Make<int>("GameTimer_Disabler", "disableCount");

    vars.Helper["gameTimer"] =
        mono.Make<IntPtr>("Vertigo2.GameTimer", "instance");

    vars.Helper["gameTime"] = mono.Make<float>("Vertigo2.GameTimer", "time");

    vars.Helper["activeLoadingScreen"] =
        mono.Make<IntPtr>("Vertigo2.LoadingScreen", "_active");

    vars.Helper["level"] =
        mono.MakeString("Vertigo2.LoadingScreen", "_active", "levelName");

    return true;
  });
}

update {
  current.isLoadingScreenActive = current.activeLoadingScreen != IntPtr.Zero &&
      vars.Helper.Read<IntPtr>(current.activeLoadingScreen + 0x10) !=
          IntPtr.Zero;

  current.isGameTimerRunning = current.gameTimer != IntPtr.Zero &&
      vars.Helper.Read<IntPtr>(current.gameTimer + 0x10) != IntPtr.Zero &&
      !current.isLoadingScreenActive && current.gameTimerDisablerCount <= 0;

  var dict = (IDictionary<string, object>)old;
  if (!dict.ContainsKey("isLoadingScreenActive") || current.isLoadingScreenActive != old.isLoadingScreenActive) {
    vars.Log("================== isLoadingScreenActive: " + current.isLoadingScreenActive);
  }
  if (!dict.ContainsKey("isGameTimerRunning") || current.isGameTimerRunning != old.isGameTimerRunning) {
    vars.Log("================== isGameTimerRunning: " + current.isGameTimerRunning);
  }
  if (!dict.ContainsKey("level") || current.level != old.level) {
    vars.Log("================== Level: " + current.level);
  }

  // old is missing stuff on first frame so doing this to avoid error
  return ((IDictionary<string, object>)old).ContainsKey("level");
}

start {
  var isNextLevelStartingLevel = settings["startAtOrigins"] ? current.level == "BrianLab" : current.level != "Menu";
  return current.level != old.level && isNextLevelStartingLevel;
}

onStart { timer.IsGameTimePaused = true; }

isLoading { return !current.isGameTimerRunning; }

gameTime {
  if (settings["useInGameTime"])
    return TimeSpan.FromSeconds(current.gameTime);
}

split {
  var didChangeLevel = current.level != old.level;
  return didChangeLevel && current.level != "Menu";
}

reset {
  if (settings["resetWithGameTimer"])
    return current.gameTime == 0f && old.gameTime != 0f;

  return current.level == "Menu" && !current.isLoadingScreenActive;
}
