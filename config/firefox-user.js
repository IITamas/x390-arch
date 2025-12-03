// Hardware video acceleration
user_pref("media.ffmpeg.vaapi.enabled", true);
user_pref("media.ffvpx.enabled", false);
user_pref("media.navigator.mediadatadecoder_vpx_enabled", true);
user_pref("media.rdd-vpx.enabled", false);
user_pref("media.av1.enabled", false);
user_pref("gfx.webrender.all", true);
user_pref("widget.wayland.dma-buf-textures.enabled", true);
user_pref("widget.dmabuf.force-enabled", true);

// Performance settings
user_pref("browser.cache.disk.enable", false);
user_pref("browser.cache.memory.enable", true);
user_pref("browser.cache.memory.capacity", 524288);
user_pref("browser.sessionstore.interval", 15000);
user_pref("content.notify.interval", 500000);
user_pref("gfx.canvas.accelerated", true);