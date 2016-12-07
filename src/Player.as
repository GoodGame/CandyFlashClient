/**
 * Created by Agat .
 */
package {
    import flash.display.Stage;
    import flash.events.Event;
    import flash.external.ExternalInterface;
    import flash.geom.Rectangle;
    import flash.media.SoundTransform;
    import flash.media.Video;

    import org.mangui.hls.HLS;
    import org.mangui.hls.event.HLSEvent;
    import org.mangui.hls.utils.ScaleVideo;

    public class Player {

        private var hls:HLS;

        private var video:Video;

        private var toPlay:Boolean = false;

        private var url:String;

        private var metrics:Object = {video_height: 0, video_width: 0};

        public function Player(videoElement:Video, stage:Stage): void {
            ExternalInterface.call('console', 'log', 'init player');

            stage.addEventListener(Event.RESIZE, stage_resizeHandler);

            // init hls
            this.hls= new HLS();
            this.hls.stage = stage;

            // set prefix to JS playlist loader
            JSURLLoader.externalCallback = 'Candy.helpers.JSLoaderPlaylist';
            // set JS playlist loader class
            this.hls.URLloader = JSURLLoader;

            // set prefix to JS fragment loader
            JSURLStream.externalCallback = 'Candy.helpers.JSLoaderFragment';
            // set JS fragment loader class
            this.hls.URLstream = JSURLStream;

            this.video = videoElement;

            this.hls.addEventListener(HLSEvent.MANIFEST_PARSED, this.onManifestParsed);
            this.hls.addEventListener(HLSEvent.PLAYBACK_STATE, this.onPlaybackStateChange);
            this.hls.addEventListener(HLSEvent.FRAGMENT_PLAYING, this.onFragmentLoaded);
            this.hls.addEventListener(HLSEvent.MEDIA_TIME, hlsEventMediaTimeHandler);
        }

        public function play(url:String): void {
            this.toPlay = true;

            if (this.url != url) {
                this.url = url;
                hls.stream.close();
                hls.load(url);
                return;
            }
        }

        public function stop():void {
            this.toPlay = false;
        }

        // every time set to JS current buffer in seconds
        private function hlsEventMediaTimeHandler(event:HLSEvent):void {
            if (event.mediatime) {
                ExternalInterface.call('Candy.helpers.setCurrentBufferTime', event.mediatime.buffer);
            }
        }

        private function onManifestParsed(event:HLSEvent): void {
            this.video.attachNetStream(this.hls.stream);
            if (toPlay) {
                this.hls.stream.soundTransform = new SoundTransform(.2);
                this.hls.stream.play();
            }
        }

        private function onPlaybackStateChange(event:HLSEvent): void {
            ExternalInterface.call('console.log', '[PLAYER]', 'on playback state', event.state);
        }

        private function onFragmentLoaded(event:HLSEvent): void {
            if (this.metrics.video_width != event.playMetrics.video_width
                || this.metrics.video_height != event.playMetrics.video_height) {

                this.metrics.video_width = event.playMetrics.video_width;
                this.metrics.video_height = event.playMetrics.video_height;

                this.resizeVideo();
            }
        }

        private function resizeVideo(): void {
            var rect:Rectangle = ScaleVideo.resizeRectangle(this.metrics.video_width,
                    this.metrics.video_height, this.video.parent.width, this.video.parent.height);
            this.video.x = rect.x;
            this.video.y = rect.x;
            this.video.width = rect.width;
            this.video.height = rect.height;
            ExternalInterface.call('console.log', '[PLAYER]', 'on resize video',
                    this.video.width, 'x', this.video.height);
        }

        private function stage_resizeHandler(event:Event):void {
            resizeVideo();
        }
    }
}
