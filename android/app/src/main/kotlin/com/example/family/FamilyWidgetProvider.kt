package com.huluca.giadinh

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class FamilyWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.family_widget).apply {
                val childName = widgetData.getString("child_name", "---") ?: "---"
                val status = widgetData.getString("status", "Offline") ?: "Offline"
                val battery = widgetData.getString("battery", "--") ?: "--"
                val location = widgetData.getString("location_text", "") ?: ""
                val lastUpdate = widgetData.getString("last_update", "") ?: ""
                val isOnline = status.lowercase() == "online"

                setTextViewText(R.id.widget_child_name, childName)
                setTextViewText(R.id.widget_status, status)
                setTextViewText(R.id.widget_battery, "🔋 $battery%")
                setTextViewText(R.id.widget_location, location)
                setTextViewText(R.id.widget_updated, lastUpdate)

                // Status dot color
                if (isOnline) {
                    setInt(R.id.widget_status, "setTextColor", 0xFF4CAF50.toInt())
                    setInt(R.id.widget_status_dot, "setBackgroundResource", R.drawable.status_dot_online)
                } else {
                    setInt(R.id.widget_status, "setTextColor", 0xFFF44336.toInt())
                    setInt(R.id.widget_status_dot, "setBackgroundResource", R.drawable.status_dot_offline)
                }
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
