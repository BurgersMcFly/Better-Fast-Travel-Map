// BetterFastTravelMap, Cyberpunk 2077 mod that improves the Fast Travel Menu
// Copyright (C) 2022 BurgersMcFly

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

@replaceMethod(WorldMapMenuGameController)
  protected cb func OnUninitialize() -> Bool {
    let evt: ref<inkMenuLayer_SetCursorType>;
    if (true) {
      this.SaveFilters();
    };
    GameInstance.GetTimeSystem(this.m_player.GetGame()).UnsetTimeDilation(n"WorldMap");
    GameInstance.GetGodModeSystem(this.m_player.GetGame()).RemoveGodMode(this.m_player.GetEntityID(), gameGodModeType.Invulnerable, n"WorldMap");
    this.m_menuEventDispatcher.UnregisterFromEvent(n"OnBack", this, n"OnBack");
    this.m_mapBlackboard.SetString(this.m_mapDefinition.currentState, "Uninitialized");
    this.UninitializeCustomFiltersList();
    inkWidgetRef.UnregisterFromCallback(this.m_preloaderWidget, n"OnFinished", this, n"OnRemovePreloader");
    evt = new inkMenuLayer_SetCursorType();
    evt.Init(n"default");
    this.QueueEvent(evt);
  }

@replaceMethod(WorldMapMenuGameController)
  protected cb func OnFilterSwitched(evt: ref<inkPointerEvent>) -> Bool {
    let filterLogic: wref<WorldMapFiltersListItem>;
    if evt.IsAction(n"click") && this.canChangeCustomFilter {
      filterLogic = evt.GetTarget().GetController() as WorldMapFiltersListItem;
      this.UpdateCustomFilter(filterLogic.GetFilterType(), filterLogic.SwitchFilter());
    };
  }

@replaceMethod(WorldMapMenuGameController)
  protected cb func OnEntityAttached() -> Bool {
    let delayEvent: ref<MapNavigationDelay>;
    let fastTravelEnabled: Bool;
    let preloaderController: wref<WorldMapPreloader>;
    let mappinSpawnContainer: wref<inkCompoundWidget> = this.GetSpawnContainer();
    mappinSpawnContainer.RegisterToCallback(n"OnEnter", this, n"OnHoverOverMappin");
    mappinSpawnContainer.RegisterToCallback(n"OnLeave", this, n"OnHoverOutMappin");
    this.RegisterToGlobalInputCallback(n"OnPostOnAxis", this, n"OnAxisInput");
    this.RegisterToGlobalInputCallback(n"OnPostOnPress", this, n"OnPressInput");
    this.RegisterToGlobalInputCallback(n"OnPostOnRelease", this, n"OnReleaseInput");
    this.RegisterToGlobalInputCallback(n"OnPostOnHold", this, n"OnHoldInput");
    this.m_cameraMode = this.GetEntityPreview().GetCameraMode();
    fastTravelEnabled = this.IsFastTravelEnabled();
    this.UpdateFastTravelVisiblity(fastTravelEnabled);
    if fastTravelEnabled {

    };
    if this.m_initPosition.X != 0.00 && this.m_initPosition.Y != 0.00 && this.m_initPosition.Z != 0.00 {
      delayEvent = new MapNavigationDelay();
      this.QueueEvent(delayEvent);
    };
    this.m_mapBlackboard.SetString(this.m_mapDefinition.currentState, "EntityAttached");
    preloaderController = inkWidgetRef.GetController(this.m_preloaderWidget) as WorldMapPreloader;
    preloaderController.SetMapLoaded();
    this.RefreshInputHints();
    this.m_entityAttached = true;
  } 

@replaceMethod(WorldMapMenuGameController)
  private final func UpdateFastTravelVisiblity(fastTravelEnabled: Bool) -> Void {
    inkWidgetRef.SetVisible(this.m_fastTravelInstructions, false);
    inkWidgetRef.SetVisible(this.m_filterSelector, true);
    inkWidgetRef.SetVisible(this.m_filtersList, true);
    inkWidgetRef.SetVisible(this.m_questContainer, !fastTravelEnabled);
    inkWidgetRef.SetVisible(this.m_topShadow, !fastTravelEnabled);
    this.ToggleQuickFilterIndicatorsVsibility(true);
  }   

@replaceMethod(WorldMapMenuGameController)
  private final func TryTrackQuestOrSetWaypoint() -> Void {
    if this.IsFastTravelEnabled() {

    };
    if this.selectedMappin != null {
      if this.selectedMappin.IsInCollection() && this.selectedMappin.IsCollection() || !this.selectedMappin.IsInCollection() {
        if this.CanQuestTrackMappin(this.selectedMappin) {
          if !this.IsMappinQuestTracked(this.selectedMappin) {
            this.UntrackCustomPositionMappin();
            this.TrackQuestMappin(this.selectedMappin);
            this.PlaySound(n"MapPin", n"OnEnable");
          };
        } else {
          if this.CanPlayerTrackMappin(this.selectedMappin) {
            if this.selectedMappin.IsCustomPositionTracked() {
              this.UntrackCustomPositionMappin();
              this.SetSelectedMappin(null);
              this.PlaySound(n"MapPin", n"OnDisable");
            } else {
              if this.selectedMappin.IsPlayerTracked() {
                this.UntrackMappin();
                this.PlaySound(n"MapPin", n"OnDisable");
              } else {
                this.UntrackCustomPositionMappin();
                this.TrackMappin(this.selectedMappin);
                this.PlaySound(n"MapPin", n"OnEnable");
              };
            };
          };
        };
        this.UpdateSelectedMappinTooltip();
      };
    } else {
      this.TrackCustomPositionMappin();
    };
    this.PlaySound(n"MapPin", n"OnCreate");
  }

@replaceMethod(WorldMapMenuGameController)
  private final func HandleReleaseInput(e: ref<inkPointerEvent>) -> Void {
    if inkWidgetRef.IsVisible(this.m_filtersList) {
      if e.IsAction(n"world_map_filter_navigation_down") {
        this.NavigateCustomFilters(ECustomFilterDPadNavigationOption.SelectNext);
      } else {
        if e.IsAction(n"world_map_filter_navigation_up") {
          this.NavigateCustomFilters(ECustomFilterDPadNavigationOption.SelectPrev);
        } else {
          if e.IsAction(n"world_map_menu_toggle_custom_filter") {
            this.NavigateCustomFilters(ECustomFilterDPadNavigationOption.Toggle);
          };
        };
      };
    };
    if e.IsAction(n"world_map_menu_move_mouse") {
      this.SetMousePanEnabled(false);
    } else {
      if e.IsAction(n"world_map_menu_cycle_filter_prev") {
        if this.canChangeCustomFilter  {
          this.CycleQuickFilterPrev();
        };
      } else {
        if e.IsAction(n"world_map_menu_cycle_filter_next") {
          if this.canChangeCustomFilter  {
            this.CycleQuickFilterNext();
          };
        } else {
          if e.IsAction(n"toggle_journal") || e.IsAction(n"world_map_menu_open_quest_static") {
            if !e.IsHandled() || !e.IsConsumed() {
              this.PlaySound(n"Button", n"OnPress");
              this.OpenTrackedQuest();
              e.Handle();
              e.Consume();
            };
          };
        };
      };
    };
  }
