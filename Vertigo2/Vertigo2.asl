state("vertigo2") {}

startup {
  Assembly.Load(File.ReadAllBytes("Components/asl-help"))
      .CreateInstance("Unity");

  vars.Helper.AlertLoadless();

  dynamic[,] settingDefs = {
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

  // old is missing stuff on first frame so doing this to avoid error
  return ((IDictionary<string, object>)old).ContainsKey("level");
}

start { return current.level != "MainMenu" && current.level != old.level; }

onStart { timer.IsGameTimePaused = true; }

isLoading { return !current.isGameTimerRunning; }

gameTime {
  if (settings["useInGameTime"])
    return TimeSpan.FromSeconds(current.gameTime);
}

split {
  var didChangeLevel = current.level != old.level;
  var didLeaveCutscene = old.level == "DreamSequences";
  var didChangeToNextLevel =
      didChangeLevel && current.level != "MainMenu" && !didLeaveCutscene;
  var didGameTimePause = !current.isGameTimerRunning &&
      old.isGameTimerRunning && current.gameTime > 0f;
  var didGameFinish = current.level == "Core" && didGameTimePause &&
      !current.isLoadingScreenActive;
  return didChangeToNextLevel || didGameFinish;
}

reset {
  if (settings["resetWithGameTimer"])
    return current.gameTime == 0f && old.gameTime != 0f;

  return current.level == "MainMenu" && !current.isLoadingScreenActive;
}
