package com.raptors.focusapp

import android.content.Context
import android.graphics.*
import android.graphics.drawable.GradientDrawable
import android.os.Build
import android.text.InputType
import android.util.Log
import android.util.TypedValue
import android.view.*
import android.widget.*
import androidx.core.content.ContextCompat

class OverlayService(private val context: Context) {
    private var windowManager: WindowManager? = null
    private var overlayView: View? = null
    private var focusModeEnabled = false
    private var currentPackage: String? = null

    init {
        windowManager = context.getSystemService(Context.WINDOW_SERVICE) as WindowManager
        Log.d("OverlayService", "OverlayService initialized")
    }

    fun setFocusMode(enabled: Boolean) {
        focusModeEnabled = enabled
        Log.d("OverlayService", "Focus mode set to: $enabled")
        if (!enabled) hideOverlay()
    }

    fun showOverlay(packageName: String) {
        Log.d("OverlayService", "Attempting to show overlay for: $packageName")

        if (!focusModeEnabled || packageName.contains("com.raptors.focusapp")) {
            hideOverlay()
            return
        }

        if (currentPackage == packageName && overlayView != null) {
            Log.d("OverlayService", "Overlay already shown for $packageName, skipping")
            return
        }

        hideOverlay()
        currentPackage = packageName

        overlayView = createOverlayView()

        val layoutParams = WindowManager.LayoutParams(
            WindowManager.LayoutParams.MATCH_PARENT,
            WindowManager.LayoutParams.MATCH_PARENT,
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
                WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
            else
                WindowManager.LayoutParams.TYPE_SYSTEM_ERROR,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                    WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL or
                    WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS,
            PixelFormat.TRANSLUCENT
        )

        layoutParams.gravity = Gravity.TOP or Gravity.START

        // Ensure the overlay is touchable and the EditText can receive input
        layoutParams.flags = layoutParams.flags and WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE.inv()
        layoutParams.flags = layoutParams.flags and WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL.inv()
        layoutParams.softInputMode = WindowManager.LayoutParams.SOFT_INPUT_ADJUST_RESIZE

        try {
            windowManager?.addView(overlayView, layoutParams)
            Log.d("OverlayService", "Overlay added successfully")
        } catch (e: Exception) {
            Log.e("OverlayService", "Failed to add overlay: ${e.message}", e)
            currentPackage = null
        }
    }

    fun hideOverlay() {
        overlayView?.let { view ->
            try {
                windowManager?.removeView(view)
                Log.d("OverlayService", "Overlay removed successfully")
            } catch (e: Exception) {
                Log.e("OverlayService", "Failed to remove overlay: ${e.message}", e)
            }
            overlayView = null
            currentPackage = null
        }
    }

    private fun dpToPx(dp: Float): Int {
        return TypedValue.applyDimension(
            TypedValue.COMPLEX_UNIT_DIP,
            dp,
            context.resources.displayMetrics
        ).toInt()
    }

    private fun createOverlayView(): View {
        Log.d("OverlayService", "Creating new popup overlay view")

        val parentLayout = FrameLayout(context)

        // Background with blur effect simulation
        val backgroundView = View(context)
        backgroundView.setBackgroundColor(Color.parseColor("#CC141431")) // rgba(20, 20, 49, 0.80)
        parentLayout.addView(backgroundView, FrameLayout.LayoutParams(
            FrameLayout.LayoutParams.MATCH_PARENT,
            FrameLayout.LayoutParams.MATCH_PARENT
        ))

        // Main Card Container
        val cardLayout = LinearLayout(context)
        cardLayout.orientation = LinearLayout.VERTICAL
        cardLayout.gravity = Gravity.CENTER

        // Card padding: reduce vertical and horizontal padding
        val paddingVertical = dpToPx(10f) // was 21f
        val paddingHorizontal = dpToPx(8f) // was 14f
        cardLayout.setPadding(paddingHorizontal, paddingVertical, paddingHorizontal, paddingVertical)

        // Card Background - Single PNG approach  
        val cardBackground = ContextCompat.getDrawable(context, R.drawable.frame_bg)
        if (cardBackground != null) {
            // Use your Frame-9 PNG background
            cardLayout.background = cardBackground
        } else {
            // Fallback gradient if PNG not available
            val fallbackBackground = GradientDrawable(
                GradientDrawable.Orientation.TOP_BOTTOM,
                intArrayOf(Color.parseColor("#6C64E9"), Color.parseColor("#1A171A"))
            )
            fallbackBackground.cornerRadius = dpToPx(29.9f).toFloat()
            cardLayout.background = fallbackBackground
        }
        
        // Add shadow effect (box-shadow: 0px 2.44px 9.15px rgba(0, 0, 0, 0.65))
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            cardLayout.elevation = dpToPx(9.15f).toFloat()
        }

        // Card width: 313px converted to dp (keep as is for width)
        val cardParams = FrameLayout.LayoutParams(
            dpToPx(313f),
            dpToPx(260f), // Set a fixed, smaller height for the card
            Gravity.CENTER
        )

        // Title Text
        val titleText = TextView(context).apply {
            text = "HOLD UP!"
            setTextColor(Color.parseColor("#F4EAEA"))
            textSize = 22f // smaller
            typeface = Typeface.DEFAULT_BOLD
            gravity = Gravity.CENTER
            // Add text shadow: 0px 2px 4px rgba(0, 0, 0, 0.41)
            setShadowLayer(4f, 0f, 2f, Color.parseColor("#69000000"))
        }
        val titleParams = LinearLayout.LayoutParams(
            LinearLayout.LayoutParams.MATCH_PARENT,
            LinearLayout.LayoutParams.WRAP_CONTENT
        )
        titleParams.bottomMargin = dpToPx(6f) // increased from 2f
        cardLayout.addView(titleText, titleParams)

        // Eye Icon - Single PNG approach
        val eyeIcon = ImageView(context).apply {
            // Just put eye.png in res/drawable/ folder
            setImageResource(R.drawable.eye)
            scaleType = ImageView.ScaleType.CENTER_INSIDE
        }
        val eyeParams = LinearLayout.LayoutParams(dpToPx(24f), dpToPx(16f))
        eyeParams.bottomMargin = dpToPx(4f) // increased from 1f
        eyeParams.gravity = Gravity.CENTER_HORIZONTAL
        cardLayout.addView(eyeIcon, eyeParams)

        // Subtitle Text
        val subtitle = TextView(context).apply {
            text = "You're currently in focus mode"
            setTextColor(Color.WHITE)
            textSize = 7f
            gravity = Gravity.CENTER
        }
        val subtitleParams = LinearLayout.LayoutParams(
            LinearLayout.LayoutParams.MATCH_PARENT,
            LinearLayout.LayoutParams.WRAP_CONTENT
        )
        subtitleParams.bottomMargin = dpToPx(4f) // increased from 1f
        cardLayout.addView(subtitle, subtitleParams)

        // Question Text
        val question = TextView(context).apply {
            text = "What is your motive to open this app?"
            setTextColor(Color.WHITE)
            textSize = 9f
            gravity = Gravity.CENTER
        }
        val questionParams = LinearLayout.LayoutParams(
            dpToPx(200f),
            LinearLayout.LayoutParams.WRAP_CONTENT
        )
        questionParams.bottomMargin = dpToPx(6f) // increased from 2f
        questionParams.gravity = Gravity.CENTER_HORIZONTAL
        cardLayout.addView(question, questionParams)

        // Input Field Container
        val inputContainer = LinearLayout(context).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
            setPadding(dpToPx(5f), 0, dpToPx(5f), 0)
            background = GradientDrawable().apply {
                cornerRadius = dpToPx(8f).toFloat()
                setStroke(dpToPx(0.7f), Color.parseColor("#6C64E9"))
                setColor(Color.parseColor("#353434"))
            }
        }
        val userInput = EditText(context).apply {
            hint = "Type here"
            setHintTextColor(Color.GRAY)
            setTextColor(Color.WHITE)
            textSize = 9f
            inputType = InputType.TYPE_CLASS_TEXT
            setBackgroundColor(Color.TRANSPARENT)
            isFocusable = true
            isFocusableInTouchMode = true
            isEnabled = true
        }
        inputContainer.addView(userInput, LinearLayout.LayoutParams(
            LinearLayout.LayoutParams.MATCH_PARENT,
            LinearLayout.LayoutParams.WRAP_CONTENT
        ))
        val inputContainerParams = LinearLayout.LayoutParams(
            dpToPx(140f),
            dpToPx(18f)
        )
        inputContainerParams.bottomMargin = dpToPx(4f) // increased from 2f
        inputContainerParams.gravity = Gravity.CENTER_HORIZONTAL
        cardLayout.addView(inputContainer, inputContainerParams)

        // Exit Button
        val exitButton = LinearLayout(context).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER
            setPadding(dpToPx(5f), 0, dpToPx(5f), 0)
            background = GradientDrawable().apply {
                cornerRadius = dpToPx(8f).toFloat()
                setColor(Color.parseColor("#6C64E9"))
            }
            setOnClickListener {
                Log.d("OverlayService", "Exit button clicked, closing overlay")
                hideOverlay()
            }
        }
        val exitButtonText = TextView(context).apply {
            text = "EXIT"
            setTextColor(Color.WHITE)
            textSize = 9f
            gravity = Gravity.CENTER
            typeface = Typeface.DEFAULT_BOLD
        }
        exitButton.addView(exitButtonText, LinearLayout.LayoutParams(
            LinearLayout.LayoutParams.MATCH_PARENT,
            LinearLayout.LayoutParams.WRAP_CONTENT
        ))
        val exitButtonParams = LinearLayout.LayoutParams(
            dpToPx(140f),
            dpToPx(18f)
        )
        exitButtonParams.gravity = Gravity.CENTER_HORIZONTAL
        cardLayout.addView(exitButton, exitButtonParams)

        parentLayout.addView(cardLayout, cardParams)

        return parentLayout
    }
}