// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2016 elementary LLC.
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * Authored by: Corentin Noël <corentin@elementary.io>
 */

public class Bluetooth.Plug : Switchboard.Plug {
    private MainView main_view;
    private Services.ObjectManager manager;
    private const string SCHEMA = "io.elementary.desktop.wingpanel.bluetooth";
    private Settings? setting_bluetooth = null;

    public Plug () {
        var settings = new Gee.TreeMap<string, string?> (null, null);
        settings.set ("network/bluetooth", null);
        Object (category: Category.NETWORK,
            code_name: "io.elementary.switchboard.bluetooth",
            display_name: _("Bluetooth"),
            description: _("Configure Bluetooth Settings"),
            icon: "bluetooth",
            supported_settings: settings);
        var settings_schema = SettingsSchemaSource.get_default ().lookup (SCHEMA, true);
        if (settings_schema != null) {
            setting_bluetooth = new Settings (SCHEMA);
        }
        manager = new Bluetooth.Services.ObjectManager ();
        manager.bind_property ("has-object", this, "can-show", GLib.BindingFlags.SYNC_CREATE);
    }

    public override Gtk.Widget get_widget () {
        if (main_view == null) {
            main_view = new MainView (manager);
            main_view.quit_plug.connect (() => hidden ());
        }

        return main_view;
    }

    public override void shown () {
        bool last_state = false;
        if (setting_bluetooth != null) {
            last_state = setting_bluetooth.get_boolean ("bluetooth-enabled");
        }
        manager.register_agent.begin (main_view.get_toplevel () as Gtk.Window);
        manager.set_global_state.begin (last_state); /* retrieving status from dconf bluetooth is a great way to make the modeswitch function useful */
    }

    public override void hidden () {
        manager.unregister_agent.begin ();
        manager.discoverable = false; /* Does not change is_powered or connections*/
        manager.stop_discovery.begin ();
    }

    public override void search_callback (string location) {

    }

    // 'search' returns results like ("Keyboard → Behavior → Duration", "keyboard<sep>behavior")
    public override async Gee.TreeMap<string, string> search (string search) {
        var search_results = new Gee.TreeMap<string, string> ((GLib.CompareDataFunc<string>)strcmp, (Gee.EqualDataFunc<string>)str_equal);
        /*search_results.set ("%s → %s".printf (display_name, _("General")), "");*/
        return search_results;
    }
}

public Switchboard.Plug get_plug (Module module) {
    debug ("Activating Bluetooth plug");
    var plug = new Bluetooth.Plug ();
    return plug;
}
