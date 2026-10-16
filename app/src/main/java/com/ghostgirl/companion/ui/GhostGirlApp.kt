package com.ghostgirl.companion.ui

import android.graphics.BitmapFactory
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.safeDrawing
import androidx.compose.foundation.layout.windowInsetsPadding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.FilterChip
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Slider
import androidx.compose.material3.Switch
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.darkColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.FilterQuality
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.IntOffset
import androidx.compose.ui.unit.IntSize
import androidx.compose.ui.unit.dp
import com.ghostgirl.companion.model.GhostCharacter
import com.ghostgirl.companion.model.GestureAction
import com.ghostgirl.companion.model.GhostMood
import com.ghostgirl.companion.model.GhostSettings
import com.ghostgirl.companion.model.LaunchableApp
import kotlin.math.roundToInt

private val Background = Color(0xFF15111F)
private val CardColor = Color(0xFF262033)
private val Rose = Color(0xFFF5A4C7)
private val Lavender = Color(0xFFC5B5FF)

@Composable
fun GhostGirlApp(
    settings: GhostSettings,
    overlayGranted: Boolean,
    notificationsGranted: Boolean,
    screenshotReady: Boolean,
    overlayRunning: Boolean,
    overlayStarting: Boolean,
    overlayError: String?,
    lastFatal: String?,
    openedFromOverlay: Boolean,
    onSettingsChanged: (GhostSettings) -> Unit,
    onRequestOverlay: () -> Unit,
    onStopOverlay: () -> Unit,
    onOpenScreenshotSettings: () -> Unit,
    onPreviewMood: (GhostMood) -> Unit,
    launchableApps: List<LaunchableApp>,
) {
    var previewMood by remember { mutableStateOf(GhostMood.IDLE) }
    var sizeValue by remember(settings.sizeDp) { mutableFloatStateOf(settings.sizeDp.toFloat()) }
    var opacityValue by remember(settings.opacity) { mutableFloatStateOf(settings.opacity) }
    var speedValue by remember(settings.animationSpeed) { mutableFloatStateOf(settings.animationSpeed) }
    var showAppPicker by remember { mutableStateOf(false) }

    MaterialTheme(colorScheme = darkColorScheme(
        primary = Rose,
        secondary = Lavender,
        background = Background,
        surface = CardColor,
        onBackground = Color.White,
        onSurface = Color.White,
    )) {
        LazyColumn(
            modifier = Modifier.fillMaxSize().background(Background).windowInsetsPadding(WindowInsets.safeDrawing),
            contentPadding = PaddingValues(start = 20.dp, end = 20.dp, top = 28.dp, bottom = 32.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp),
        ) {
            item {
                Text("PixiePop", style = MaterialTheme.typography.headlineLarge,
                    fontWeight = FontWeight.Bold, color = Rose)
                Text("Bạn đồng hành nổi trên màn hình", color = Lavender)
            }
            item {
                Card(colors = CardDefaults.cardColors(containerColor = CardColor),
                    shape = RoundedCornerShape(22.dp), modifier = Modifier.fillMaxWidth()) {
                    Column(Modifier.padding(18.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                        Text("Thao tác chạm", style = MaterialTheme.typography.titleLarge,
                            fontWeight = FontWeight.Bold)
                        GestureActionPicker("Chạm 2 lần", settings.doubleTapAction) {
                            onSettingsChanged(settings.copy(doubleTapAction = it))
                        }
                        GestureActionPicker("Chạm 3 lần", settings.tripleTapAction) {
                            onSettingsChanged(settings.copy(tripleTapAction = it))
                        }
                        val appLabel = if (settings.openAppComponent == null) "ChatGPT (mặc định)"
                            else launchableApps.firstOrNull { it.component == settings.openAppComponent }?.label
                                ?: "Ứng dụng đã chọn"
                        OutlinedButton(onClick = { showAppPicker = true }, modifier = Modifier.fillMaxWidth()) {
                            Text("Ứng dụng để mở: $appLabel")
                        }
                        Text(if (screenshotReady)
                            "Chụp ảnh toàn màn hình đã sẵn sàng. Ảnh lưu vào Pictures/PixiePop."
                            else "Để chụp ảnh ngay mà không chọn ứng dụng/màn hình mỗi lần, bật dịch vụ PixiePop chụp màn hình trong Cài đặt trợ năng một lần.",
                            color = Color.LightGray, style = MaterialTheme.typography.bodySmall)
                        OutlinedButton(onClick = onOpenScreenshotSettings,
                            modifier = Modifier.fillMaxWidth()) {
                            Text(if (screenshotReady) "Quản lý quyền chụp màn hình"
                                else "Cấp quyền chụp màn hình")
                        }
                        if (!screenshotReady) Text("Nếu Android chặn quyền cho APK cài ngoài, mở Thông tin ứng dụng PixiePop → ⋮ → Cho phép cài đặt bị hạn chế, rồi quay lại bật dịch vụ.",
                            color = Color.LightGray, style = MaterialTheme.typography.bodySmall)
                        Text("Quay màn hình vẫn cần Android xác nhận mỗi lần bắt đầu. Chạm lại thao tác quay để dừng.",
                            color = Color.LightGray, style = MaterialTheme.typography.bodySmall)
                    }
                }
            }
            item {
                Card(colors = CardDefaults.cardColors(containerColor = CardColor),
                    shape = RoundedCornerShape(22.dp), modifier = Modifier.fillMaxWidth()) {
                    Column(Modifier.fillMaxWidth().padding(16.dp),
                        horizontalAlignment = Alignment.CenterHorizontally) {
                        GhostSpritePreview(settings.character, previewMood)
                        Spacer(Modifier.height(8.dp))
                        Text("${settings.character.label} · ${previewMood.label}", fontWeight = FontWeight.SemiBold)
                        Text("Art prototype theo ảnh tham chiếu, có thể thay sprite", color = Color.LightGray,
                            style = MaterialTheme.typography.bodySmall)
                    }
                }
            }
            item {
                Text("Chọn nhân vật", style = MaterialTheme.typography.titleLarge,
                    fontWeight = FontWeight.Bold)
                Row(Modifier.fillMaxWidth().horizontalScroll(rememberScrollState()),
                    horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    GhostCharacter.entries.forEach { character ->
                        FilterChip(selected = settings.character == character,
                            onClick = {
                                previewMood = GhostMood.IDLE
                                onSettingsChanged(settings.copy(character = character))
                            }, label = { Text(character.label) })
                    }
                }
            }
            item {
                Row(Modifier.fillMaxWidth().horizontalScroll(rememberScrollState()),
                    horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    GhostMood.entries.forEach { mood ->
                        FilterChip(selected = previewMood == mood, onClick = {
                            previewMood = mood
                            onPreviewMood(mood)
                        }, label = { Text(mood.label) })
                    }
                }
            }
            item {
                Card(colors = CardDefaults.cardColors(containerColor = CardColor),
                    shape = RoundedCornerShape(22.dp), modifier = Modifier.fillMaxWidth()) {
                    Column(Modifier.padding(18.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) {
                        Text("Nhân vật nổi", style = MaterialTheme.typography.titleLarge,
                            fontWeight = FontWeight.Bold)
                        Text(if (overlayGranted) "Quyền hiển thị trên ứng dụng khác: đã cấp"
                            else "Cần cấp quyền hiển thị trên ứng dụng khác",
                            color = if (overlayGranted) Lavender else Rose)
                        if (!notificationsGranted) {
                            Text("Thông báo đang tắt. Android vẫn có thể chạy dịch vụ nổi; có thể bật thông báo để thấy nút Dừng.",
                                color = Color.LightGray, style = MaterialTheme.typography.bodySmall)
                        }
                        if (openedFromOverlay) Text("Đã mở cài đặt bằng cách giữ nhân vật.", color = Lavender)
                        if (overlayRunning) Text("Nhân vật đang nổi. Hãy về màn hình chính để xem.", color = Lavender)
                        if (overlayStarting) Text("Đang tạo cửa sổ nổi…", color = Lavender)
                        if (overlayError != null) Text(overlayError, color = Rose,
                            style = MaterialTheme.typography.bodySmall)
                        if (lastFatal != null) Text("Lỗi lần chạy trước: $lastFatal. Hãy chụp đoạn này gửi để kiểm tra.",
                            color = Rose, style = MaterialTheme.typography.bodySmall)
                        Button(onClick = onRequestOverlay, enabled = !overlayRunning && !overlayStarting,
                            modifier = Modifier.fillMaxWidth(),
                            colors = ButtonDefaults.buttonColors(containerColor = Rose,
                                contentColor = Background)) {
                            Text(if (overlayStarting) "Đang khởi động…" else if (overlayGranted)
                                "Bắt đầu nhân vật nổi" else "Cấp quyền và bắt đầu")
                        }
                        OutlinedButton(onClick = onStopOverlay, enabled = overlayRunning,
                            modifier = Modifier.fillMaxWidth()) { Text("Dừng nhân vật nổi") }
                    }
                }
            }
            item {
                Card(colors = CardDefaults.cardColors(containerColor = CardColor),
                    shape = RoundedCornerShape(22.dp), modifier = Modifier.fillMaxWidth()) {
                    Column(Modifier.padding(18.dp)) {
                        Text("Cài đặt nhân vật", style = MaterialTheme.typography.titleLarge,
                            fontWeight = FontWeight.Bold)
                        Spacer(Modifier.height(12.dp))
                        Text("Kích thước: ${sizeValue.roundToInt()} dp")
                        Slider(value = sizeValue, onValueChange = { sizeValue = it },
                            onValueChangeFinished = {
                                onSettingsChanged(settings.copy(sizeDp = sizeValue.roundToInt()))
                            }, valueRange = 72f..240f)
                        Text("Độ mờ: ${(opacityValue * 100).roundToInt()}%")
                        Slider(value = opacityValue, onValueChange = { opacityValue = it },
                            onValueChangeFinished = {
                                onSettingsChanged(settings.copy(opacity = opacityValue))
                            }, valueRange = 0.4f..1f)
                        Text("Tốc độ hoạt ảnh: ${"%.1f".format(speedValue)}×")
                        Slider(value = speedValue, onValueChange = { speedValue = it },
                            onValueChangeFinished = {
                                onSettingsChanged(settings.copy(animationSpeed = speedValue))
                            }, valueRange = 0.5f..2f)
                        Row(Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
                            Column(Modifier.weight(1f)) {
                                Text("Bám cạnh màn hình")
                                Text("Thả nhân vật để về cạnh gần nhất", color = Color.LightGray,
                                    style = MaterialTheme.typography.bodySmall)
                            }
                            Switch(checked = settings.snapToEdge,
                                onCheckedChange = { onSettingsChanged(settings.copy(snapToEdge = it)) })
                        }
                    }
                }
            }
            item {
                Text("Chạm 1 lần: mở ChatGPT hoặc Play Store. Chạm 2/3 lần: thao tác đã chọn ở trên. Nhấn giữ: mở cài đặt. Kéo: di chuyển. PixiePop không tự mở Voice và không cần API key.",
                    color = Color.LightGray, style = MaterialTheme.typography.bodySmall)
            }
        }
        if (showAppPicker) {
            AlertDialog(onDismissRequest = { showAppPicker = false },
                title = { Text("Chọn ứng dụng") },
                text = {
                    LazyColumn(Modifier.heightIn(max = 360.dp)) {
                        item {
                            TextButton(onClick = {
                                onSettingsChanged(settings.copy(openAppComponent = null))
                                showAppPicker = false
                            }) { Text("ChatGPT (mặc định)") }
                        }
                        items(launchableApps) { app ->
                            TextButton(onClick = {
                                onSettingsChanged(settings.copy(openAppComponent = app.component))
                                showAppPicker = false
                            }) { Text(app.label) }
                        }
                    }
                },
                confirmButton = { TextButton(onClick = { showAppPicker = false }) { Text("Đóng") } })
        }
    }
}

@Composable
private fun GestureActionPicker(title: String, selected: GestureAction, onSelected: (GestureAction) -> Unit) {
    var expanded by remember { mutableStateOf(false) }
    Column {
        Text(title, color = Lavender)
        OutlinedButton(onClick = { expanded = true }, modifier = Modifier.fillMaxWidth()) {
            Text(selected.label)
        }
        DropdownMenu(expanded = expanded, onDismissRequest = { expanded = false }) {
            GestureAction.entries.forEach { action ->
                DropdownMenuItem(text = { Text(action.label) }, onClick = {
                    expanded = false
                    onSelected(action)
                })
            }
        }
    }
}

@Composable
private fun GhostSpritePreview(character: GhostCharacter, mood: GhostMood) {
    val context = LocalContext.current
    val atlas = remember(character) {
        context.assets.open(character.asset).use { BitmapFactory.decodeStream(it) }.asImageBitmap()
    }
    Canvas(Modifier.size(208.dp)) {
        val bounds = character.bounds(atlas.width, atlas.height, mood)
        val aspect = (bounds.right - bounds.left).toFloat() / (bounds.bottom - bounds.top)
        val fitWidth = minOf(size.width, size.height * aspect).roundToInt()
        val fitHeight = minOf(size.height, size.width / aspect).roundToInt()
        drawImage(
            image = atlas,
            srcOffset = IntOffset(bounds.left, bounds.top),
            srcSize = IntSize(bounds.right - bounds.left, bounds.bottom - bounds.top),
            dstOffset = IntOffset((size.width.roundToInt() - fitWidth) / 2,
                (size.height.roundToInt() - fitHeight) / 2),
            dstSize = IntSize(fitWidth, fitHeight),
            filterQuality = FilterQuality.None,
        )
    }
}
