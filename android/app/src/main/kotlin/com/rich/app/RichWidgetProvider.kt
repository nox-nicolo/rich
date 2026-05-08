package com.rich.app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Build
import android.widget.RemoteViews

private const val PREFS_NAME = "rich_widget_snapshot"

abstract class BaseRichWidgetProvider(
    private val layoutId: Int,
    private val compact: Boolean,
) : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        for (id in appWidgetIds) {
            appWidgetManager.updateAppWidget(id, buildViews(context))
        }
    }

    protected fun buildViews(context: Context): RemoteViews {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val views = RemoteViews(context.packageName, layoutId)

        fun text(key: String, fallback: String): String =
            prefs.getString(key, fallback).orEmpty().ifBlank { fallback }

        views.setTextViewText(R.id.widget_updated, "UPDATED ${text("updatedAt", "--:--")}")
        views.setTextViewText(R.id.widget_work_title, text("nextWorkTitle", "No work item"))
        views.setTextViewText(R.id.widget_work_meta, text("nextWorkMeta", "Open RICH"))
        views.setTextViewText(R.id.widget_life_title, text("lifeTitle", "Life discipline"))
        views.setTextViewText(R.id.widget_life_meta, text("lifeMeta", "Keep the standard"))
        views.setTextViewText(R.id.widget_health_title, text("healthTitle", "Health status"))
        views.setTextViewText(R.id.widget_health_meta, text("healthMeta", "Log today"))
        views.setTextViewText(R.id.widget_trading_amount, text("tradingAmount", "Trading not set"))
        views.setTextViewText(R.id.widget_betting_amount, text("bettingAmount", "Betting not set"))

        if (!compact) {
            views.setTextViewText(R.id.widget_trading_meta, text("tradingMeta", "Open trades"))
            views.setTextViewText(R.id.widget_betting_meta, text("bettingMeta", "Active plan"))
            views.setTextViewText(R.id.widget_trading_news, text("tradingNews", "No trading news yet"))
            views.setTextViewText(R.id.widget_betting_news, text("bettingNews", "No betting news yet"))
            views.setTextViewText(R.id.widget_milestone_title, text("milestoneTitle", "Milestone"))
            views.setTextViewText(R.id.widget_milestone_meta, text("milestoneMeta", "Review target"))
        }

        views.setOnClickPendingIntent(R.id.widget_root, launchIntent(context))
        return views
    }

    private fun launchIntent(context: Context): PendingIntent {
        val intent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
        }
        val flags = PendingIntent.FLAG_UPDATE_CURRENT or
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                PendingIntent.FLAG_IMMUTABLE
            } else {
                0
            }
        return PendingIntent.getActivity(context, 0, intent, flags)
    }
}

class RichGlanceWidgetProvider : BaseRichWidgetProvider(
    R.layout.rich_widget_glance,
    compact = true,
)

class RichCommandWidgetProvider : BaseRichWidgetProvider(
    R.layout.rich_widget_command,
    compact = false,
)

object RichWidgetUpdater {
    fun updateAll(context: Context) {
        val manager = AppWidgetManager.getInstance(context)
        update(context, manager, RichGlanceWidgetProvider::class.java)
        update(context, manager, RichCommandWidgetProvider::class.java)
    }

    private fun update(
        context: Context,
        manager: AppWidgetManager,
        provider: Class<out AppWidgetProvider>,
    ) {
        val component = ComponentName(context, provider)
        val ids = manager.getAppWidgetIds(component)
        if (ids.isNotEmpty()) {
            val intent = Intent(context, provider).apply {
                action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, ids)
            }
            context.sendBroadcast(intent)
        }
    }
}
