import Foundation
import CoreLocation
import os.log

let RWA_MAXNUMBEROFPATCHERS = 30
let RWA_MAXNUMBEROFSTEREOPATCHERS = 15;
let RWA_MAXNUMBEROF5CHANNELPATCHERS = 4;
let RWA_MAXNUMBEROFDYNAMICPATCHERS = 50

var activeLoop = 0
var sceneChanged = false
var stateChanged = false
var rwagameloop:RwaGameLoop = RwaGameLoop()
var dynamicPatchCounter = 0;

struct pdPatcher {
    var patcherTag:UnsafeMutableRawPointer
    var isBusy:Bool = false
    var myAsset:RwaAsset
};

class RwaGameLoop:NSObject, PdListener
{
    var dispatcher:PdDispatcher?
    var monoPatchers:[pdPatcher] = []
    var stereoPatchers:[pdPatcher] = []
    var binauralMonoPatchers:[pdPatcher] = []
    var binauralStereoPatchers:[pdPatcher] = []
    var binaural5ChannelPatchers:[pdPatcher] = []
    
    var binauralMonoPatchers_fabian:[pdPatcher] = []
    var binauralStereoPatchers_fabian:[pdPatcher] = []
    var binaural5ChannelPatchers_fabian:[pdPatcher] = []
    var binaural7ChannelPatchers_fabian:[pdPatcher] = []
    
    var dynamicPatchers:[pdPatcher] = []
    var stereoOut:UnsafeMutableRawPointer?
    var isRunning = false
    var assetFolder:String = String();
    
    override init()
    {
        stereoOut = nil
        dispatcher = PdDispatcher()
        PdBase.setDelegate(dispatcher)
        //rwa_binauralrir_tilde_setup();
        rwa_binauralsimple_tilde_setup();
        //rwa_reverb_tilde_setup();
        freeverb_tilde_setup();
        
         super.init()
       
        stereoOut = PdBase.openFile("stereoout.pd", path: Bundle.main.resourcePath)
        if stereoOut == nil {
            print("Failed to open patch!")
        }
        
        for _ in 0 ..< RWA_MAXNUMBEROFPATCHERS
        {
            var patch:pdPatcher
            patch = pdPatcher.init(patcherTag: PdBase.openFile("rwaplayermonobinaural_fabian.pd", path: Bundle.main.resourcePath) ,  isBusy: false, myAsset: RwaAsset())
            binauralMonoPatchers_fabian.append(patch)
            let tag:Int32 = PdBase.dollarZero(forFile: patch.patcherTag)
            let receivedFromPd:String = "\(tag)-playfinished"
            dispatcher?.add(self, forSource: receivedFromPd)
        }
        
        for _ in 0 ..< RWA_MAXNUMBEROFSTEREOPATCHERS
        {
            var patch:pdPatcher
            patch = pdPatcher.init(patcherTag: PdBase.openFile("rwaplayerstereobinaural_fabian.pd", path: Bundle.main.resourcePath) ,  isBusy: false, myAsset: RwaAsset())
            binauralStereoPatchers_fabian.append(patch)
            let tag:Int32 = PdBase.dollarZero(forFile: patch.patcherTag)
            let receivedFromPd:String = "\(tag)-playfinished"
            dispatcher?.add(self, forSource: receivedFromPd)
        }
        
        for _ in 0 ..< RWA_MAXNUMBEROF5CHANNELPATCHERS
        {
            var patch:pdPatcher
            patch = pdPatcher.init(patcherTag: PdBase.openFile("rwaplayer5_1channelbinaural_fabian.pd", path: Bundle.main.resourcePath) ,  isBusy: false, myAsset: RwaAsset())
            binaural5ChannelPatchers_fabian.append(patch)
            let tag:Int32 = PdBase.dollarZero(forFile: patch.patcherTag)
            let receivedFromPd:String = "\(tag)-playfinished"
            dispatcher?.add(self, forSource: receivedFromPd)
        }
        
        for _ in 0 ..< RWA_MAXNUMBEROF5CHANNELPATCHERS
        {
            var patch:pdPatcher
            patch = pdPatcher.init(patcherTag: PdBase.openFile("rwaplayer7channelbinaural_fabian.pd", path: Bundle.main.resourcePath) ,  isBusy: false, myAsset: RwaAsset())
            binaural7ChannelPatchers_fabian.append(patch)
            let tag:Int32 = PdBase.dollarZero(forFile: patch.patcherTag)
            let receivedFromPd:String = "\(tag)-playfinished"
            dispatcher?.add(self, forSource: receivedFromPd)
        }
        
        for _ in 0 ..< RWA_MAXNUMBEROFPATCHERS
        {
            var patch:pdPatcher
            patch = pdPatcher.init(patcherTag: PdBase.openFile("rwaloopplayerstereo.pd", path: Bundle.main.resourcePath) ,  isBusy: false, myAsset: RwaAsset())
            stereoPatchers.append(patch)
            let tag:Int32 = PdBase.dollarZero(forFile: patch.patcherTag)
            let receivedFromPd:String = "\(tag)-playfinished"
            dispatcher?.add(self, forSource: receivedFromPd)
        }
        
        for _ in 0 ..< RWA_MAXNUMBEROFPATCHERS
        {
            var patch:pdPatcher
            patch = pdPatcher.init(patcherTag: PdBase.openFile("rwaloopplayermono.pd", path: Bundle.main.resourcePath) ,  isBusy: false, myAsset: RwaAsset())
            monoPatchers.append(patch)
            let tag:Int32 = PdBase.dollarZero(forFile: patch.patcherTag)
            let receivedFromPd:String = "\(tag)-playfinished"
            dispatcher?.add(self, forSource: receivedFromPd)
        }
    }
    
    func initDynamicPatchers()
    {
        freeDynamicPatchers()
        
        for scene in scenes
        {
            for state in scene.states
            {
                for asset in state.assets
                {
                    if (Int(asset.type) == RWAASSETTYPE_PD && !asset.mute)
                    {
                        var patch:pdPatcher
                        patch = pdPatcher.init(patcherTag: PdBase.openFile(asset.name, path: fullAssetPath) ,  isBusy: false, myAsset: asset)
                       // if(patch.patcherTag != nil)
                        
                        dynamicPatchers.append(patch)
                        print("Init Patcher: \(patch.myAsset.name) \(dynamicPatchers.count)")
                        let tag:Int32 = PdBase.dollarZero(forFile: patch.patcherTag)
                        let receivedFromPd:String = "\(tag)-playfinished"
                        dispatcher?.add(self, forSource: receivedFromPd)
                        dynamicPatchCounter += 1
                        
                    }
                }
            }
        }
    }
    
    func freeDynamicPatchers()
    {
        for i in 0 ..< dynamicPatchCounter
        {
            dynamicPatchers[i].isBusy = false
            dynamicPatchers[i].myAsset = RwaAsset()
            let tag:Int32 = PdBase.dollarZero(forFile: dynamicPatchers[i].patcherTag)
            let receivedFromPd:String = "\(tag)-playfinished"
            dispatcher?.remove(self, forSource: receivedFromPd)
            print("freepatcher");
            PdBase.closeFile(dynamicPatchers[i].patcherTag)
        }
        dynamicPatchers.removeAll();
        dynamicPatchCounter = 0
    }
    
    func findFreePatcher(asset: RwaAsset) ->Int32
    {
        if(Int(asset.type) == RWAASSETTYPE_PD) {
            return findFreeDynamicPatcher(asset: asset) }
        
        else
        {
            switch(asset.playbackType)
            {
                case Int32(RWAPLAYBACKTYPE_MONO):
                    return findFreeMonoPatcher()
                
                case Int32(RWAPLAYBACKTYPE_STEREO):
                    return findFreeStereoPatcher()
                    
                case Int32(RWAPLAYBACKTYPE_BINAURALMONO):
                    return  findFreeBinauralMonoPatcher()
                
                case Int32(RWAPLAYBACKTYPE_BINAURALMONO_FABIAN):
                    return  findFreeBinauralMonoFabianPatcher()
                    
                case Int32(RWAPLAYBACKTYPE_BINAURAL5CHANNEL):
                    return findFreeBinaural5ChannelPatcher()
                
                case Int32(RWAPLAYBACKTYPE_BINAURAL5CHANNEL_FABIAN):
                    return findFreeBinaural5ChannelFabianPatcher()
                
                case Int32(RWAPLAYBACKTYPE_BINAURAL7CHANNEL_FABIAN):
                    return findFreeBinaural7ChannelFabianPatcher()
                
                case Int32(RWAPLAYBACKTYPE_BINAURALSTEREO):
                    return findFreeBinauralStereoPatcher()
                
                case Int32(RWAPLAYBACKTYPE_BINAURALSTEREO_FABIAN):
                    return findFreeBinauralStereoFabianPatcher()
                
                case Int32(RWAPLAYBACKTYPE_NATIVE):
                    
                    if(asset.numberOfChannels == 1) {
                        return findFreeMonoPatcher()
                    }
                    
                    if(asset.numberOfChannels == 2) {
                        return findFreeStereoPatcher()                    }
                
                case Int32(RWAPLAYBACKTYPE_BINAURALAUTO):
                    
                    if(asset.numberOfChannels == 1) {
                        return findFreeBinauralMonoPatcher()
                    }
                    
                    if(asset.numberOfChannels == 2) {
                        return findFreeBinauralStereoPatcher()
                    }
                
                    if(asset.numberOfChannels == 5) {
                        return findFreeBinaural5ChannelPatcher()
                    }
                
                default:
                    return -1
            }
        }
        return -1
    }
    
    func findFreeDynamicPatcher(asset: RwaAsset) ->Int32
    {

        for i in 0 ..< dynamicPatchCounter
        {
            if (asset.name == dynamicPatchers[i].myAsset.name )
            {
                dynamicPatchers[i].isBusy = true
                return PdBase.dollarZero(forFile: dynamicPatchers[i].patcherTag)
            }
        }
        return -1
    }
    
    func findFreeMonoPatcher() ->Int32
    {

        for i in 0 ..< RWA_MAXNUMBEROFPATCHERS
        {
            if !monoPatchers[i].isBusy
            {
                monoPatchers[i].isBusy = true
                return PdBase.dollarZero(forFile: monoPatchers[i].patcherTag)
            }
        }
        return -1
    }
    
    func findFreeStereoPatcher() ->Int32
    {

        for i in 0 ..< RWA_MAXNUMBEROFPATCHERS
        {
            if !stereoPatchers[i].isBusy
            {
                stereoPatchers[i].isBusy = true
                return PdBase.dollarZero(forFile: stereoPatchers[i].patcherTag)
            }
        }
        return -1
    }
    
    func findFreeBinauralMonoPatcher() -> Int32
    {
        for i in 0 ..< RWA_MAXNUMBEROFPATCHERS
        {
            if !binauralMonoPatchers[i].isBusy
            {
                binauralMonoPatchers[i].isBusy = true
                return PdBase.dollarZero(forFile: binauralMonoPatchers[i].patcherTag)
            }
        }

        return -1
    }
    
    func findFreeBinauralMonoFabianPatcher() -> Int32
    {
        for i in 0 ..< RWA_MAXNUMBEROFPATCHERS
        {
            if !binauralMonoPatchers_fabian[i].isBusy
            {
                binauralMonoPatchers_fabian[i].isBusy = true
                return PdBase.dollarZero(forFile: binauralMonoPatchers_fabian[i].patcherTag)
            }
        }
        
        return -1
    }
    
    func findFreeBinauralStereoPatcher() ->Int32
    {

        for i in 0 ..< RWA_MAXNUMBEROFSTEREOPATCHERS
        {
            if !binauralStereoPatchers[i].isBusy
            {
                binauralStereoPatchers[i].isBusy = true
                return PdBase.dollarZero(forFile: binauralStereoPatchers[i].patcherTag)
            }
        }
        return -1
    }
    
    func findFreeBinauralStereoFabianPatcher() ->Int32
    {
        
        for i in 0 ..< RWA_MAXNUMBEROFSTEREOPATCHERS
        {
            if !binauralStereoPatchers_fabian[i].isBusy
            {
                binauralStereoPatchers_fabian[i].isBusy = true
                return PdBase.dollarZero(forFile: binauralStereoPatchers_fabian[i].patcherTag)
            }
        }
        return -1
    }
    
    func findFreeBinaural5ChannelPatcher() ->Int32
    {
        for i in 0 ..< RWA_MAXNUMBEROF5CHANNELPATCHERS
        {
            if !binaural5ChannelPatchers[i].isBusy
            {
                binaural5ChannelPatchers[i].isBusy = true
                return PdBase.dollarZero(forFile: binaural5ChannelPatchers[i].patcherTag)
            }
        }
        return -1
    }
    
    func findFreeBinaural5ChannelFabianPatcher() ->Int32
    {
        for i in 0 ..< RWA_MAXNUMBEROF5CHANNELPATCHERS
        {
            if !binaural5ChannelPatchers_fabian[i].isBusy
            {
                binaural5ChannelPatchers_fabian[i].isBusy = true
                return PdBase.dollarZero(forFile: binaural5ChannelPatchers_fabian[i].patcherTag)
            }
        }
        return -1
    }
    
    func findFreeBinaural7ChannelFabianPatcher() ->Int32
    {
        for i in 0 ..< RWA_MAXNUMBEROF5CHANNELPATCHERS
        {
            if !binaural7ChannelPatchers_fabian[i].isBusy
            {
                binaural7ChannelPatchers_fabian[i].isBusy = true
                return PdBase.dollarZero(forFile: binaural7ChannelPatchers_fabian[i].patcherTag)
            }
        }
        return -1
    }
    
    func releasePatcherFromItem(_ entityItem:RwaEntity.AssetMapItem)
    {
        let asset = entityItem.asset
        let patcherTag = entityItem.patcherTag
        let playbackType = asset.playbackType
        
        if(Int(asset.type) == RWAASSETTYPE_PD) {
            dynamicPatchers[getDynamicPatcherIndex(patcherTag)].isBusy = false
        }
        
        else
        {
            switch(playbackType)
            {
                case Int32(RWAPLAYBACKTYPE_NATIVE):
                    
                    if(asset.numberOfChannels == 1) {
                        monoPatchers[getMonoPatcherIndex(patcherTag)].isBusy = false
                    }
                    
                    if(asset.numberOfChannels == 2) {
                        stereoPatchers[getStereoPatcherIndex(patcherTag)].isBusy = false
                    }
                    break
                
                case Int32(RWAPLAYBACKTYPE_BINAURALAUTO):
                    
                    if(asset.numberOfChannels == 1) {
                        binauralMonoPatchers[getBinauralMonoPatcherIndex(patcherTag)].isBusy = false
                    }
                    
                    if(asset.numberOfChannels == 2) {
                        binauralStereoPatchers[getBinauralStereoPatcherIndex(patcherTag)].isBusy = false
                    }
                    break
                
                case Int32(RWAPLAYBACKTYPE_MONO):
                    monoPatchers[getMonoPatcherIndex(patcherTag)].isBusy = false
                    break
                
                case Int32(RWAPLAYBACKTYPE_STEREO):
                    stereoPatchers[getStereoPatcherIndex(patcherTag)].isBusy = false
                    break
                    
                case Int32(RWAPLAYBACKTYPE_BINAURALMONO):
                    binauralMonoPatchers[getBinauralMonoPatcherIndex(patcherTag)].isBusy = false
                    break
                
                case Int32(RWAPLAYBACKTYPE_BINAURALMONO_FABIAN):
                    binauralMonoPatchers_fabian[getBinauralMonoFabianPatcherIndex(patcherTag)].isBusy = false
                    break
                    
                case Int32(RWAPLAYBACKTYPE_BINAURALSTEREO):
                    binauralStereoPatchers[getBinauralStereoPatcherIndex(patcherTag)].isBusy = false
                    break
                
                case Int32(RWAPLAYBACKTYPE_BINAURALSTEREO_FABIAN):
                    binauralStereoPatchers_fabian[getBinauralStereoFabianPatcherIndex(patcherTag)].isBusy = false
                    break
                
                case Int32(RWAPLAYBACKTYPE_BINAURAL5CHANNEL):
                    binaural5ChannelPatchers[getBinaural5ChannlePatcherIndex(patcherTag)].isBusy = false
                    break
                
                case Int32(RWAPLAYBACKTYPE_BINAURAL5CHANNEL_FABIAN):
                    binaural5ChannelPatchers_fabian[getBinaural5ChannelFabianPatcherIndex(patcherTag)].isBusy = false
                    break
                
                case Int32(RWAPLAYBACKTYPE_BINAURAL7CHANNEL_FABIAN):
                    binaural7ChannelPatchers_fabian[getBinaural7ChannelFabianPatcherIndex(patcherTag)].isBusy = false
                    break
                
                default: break
            }
        }
    }
    
    func getDynamicPatcherIndex(_ tag:Int32) ->Int
    {
        for i in 0 ..< dynamicPatchCounter
        {
            if (PdBase.dollarZero(forFile: dynamicPatchers[i].patcherTag)  == tag) {
                return i
            }
        }
        return -1
    }
    
    func getMonoPatcherIndex(_ tag:Int32) ->Int
    {
        for i in 0 ..< RWA_MAXNUMBEROFPATCHERS
        {
            if (PdBase.dollarZero(forFile: monoPatchers[i].patcherTag)  == tag) {
                return i
            }
        }
        return -1
    }
    
    func getStereoPatcherIndex(_ tag:Int32) ->Int
    {
        for i in 0 ..< RWA_MAXNUMBEROFPATCHERS
        {
            if (PdBase.dollarZero(forFile: stereoPatchers[i].patcherTag)  == tag) {
                return i
            }
            
        }
        return -1
    }
    
    func getBinauralMonoPatcherIndex(_ tag:Int32) ->Int
    {
        for i in 0 ..< RWA_MAXNUMBEROFPATCHERS
        {
            if (PdBase.dollarZero(forFile: binauralMonoPatchers[i].patcherTag)  == tag) {
                return i
            }
        }
        return -1
    }
    
    func getBinauralMonoFabianPatcherIndex(_ tag:Int32) ->Int
    {
        for i in 0 ..< RWA_MAXNUMBEROFPATCHERS
        {
            if (PdBase.dollarZero(forFile: binauralMonoPatchers_fabian[i].patcherTag)  == tag) {
                return i
            }
        }
        return -1
    }
    
    func getBinauralStereoPatcherIndex(_ tag:Int32) ->Int
    {
        for i in 0 ..< RWA_MAXNUMBEROFSTEREOPATCHERS
        {
            if (PdBase.dollarZero(forFile: binauralStereoPatchers[i].patcherTag)  == tag) {
                return i
            }
        }
        return -1
    }
    
    func getBinauralStereoFabianPatcherIndex(_ tag:Int32) ->Int
    {
        for i in 0 ..< RWA_MAXNUMBEROFSTEREOPATCHERS
        {
            if (PdBase.dollarZero(forFile: binauralStereoPatchers_fabian[i].patcherTag)  == tag) {
                return i
            }
        }
        return -1
    }
    
    func getBinaural5ChannlePatcherIndex(_ tag:Int32) ->Int
    {
        for i in 0 ..< RWA_MAXNUMBEROF5CHANNELPATCHERS
        {
            if (PdBase.dollarZero(forFile: binaural5ChannelPatchers[i].patcherTag)  == tag) {
                return i
            }
            
        }
        return -1
    }
    
    func getBinaural5ChannelFabianPatcherIndex(_ tag:Int32) ->Int
    {
        for i in 0 ..< RWA_MAXNUMBEROF5CHANNELPATCHERS
        {
            if (PdBase.dollarZero(forFile: binaural5ChannelPatchers_fabian[i].patcherTag)  == tag) {
                return i
            }
            
        }
        return -1
    }
    
    func getBinaural7ChannelFabianPatcherIndex(_ tag:Int32) ->Int
    {
        for i in 0 ..< RWA_MAXNUMBEROF5CHANNELPATCHERS
        {
            if (PdBase.dollarZero(forFile: binaural7ChannelPatchers_fabian[i].patcherTag)  == tag) {
                return i
            }
            
        }
        return -1
    }
    
    func sendEnd2BackgroundAssets()
    {
        if(!hero.backgroundAssets.isEmpty)
        {
            for entityAsset in hero.backgroundAssets
            {
               let patcherTag = entityAsset.value.patcherTag
               let send2pd = "\(patcherTag)-end"
               PdBase.sendBang(toReceiver: send2pd)
                
                if #available(iOS 10.0, *) {
                    os_log("%@", type: .debug, "Send End to Background Asset: \(entityAsset.value.asset.name) with patchertag: \(patcherTag)")
                } else {
                    print("Send End to Background Asset: \(entityAsset.value.asset.name) with patchertag: \(patcherTag)")
                }
            }
        }
    }
    
    func sendEnd2ActiveAssets()
    {
        if(!hero.activeAssets.isEmpty)
        {
            for entityAsset in hero.activeAssets
            {
                let patcherTag = entityAsset.value.patcherTag
                let send2pd = "\(patcherTag)-end"
                PdBase.sendBang(toReceiver: send2pd)
                
                if #available(iOS 10.0, *) {
                    os_log("%@", type: .debug, "Send End to Active Asset: \(entityAsset.value.asset.name) with patchertag: \(patcherTag)")
                } else {
                    print("Send End to Active Asset: \(entityAsset.value.asset.name) with patchertag: \(patcherTag)")
                }
            }
        }
        
        if(!hero.assets2Unblock.isEmpty)
        {
            for asset in hero.assets2Unblock
            {
                asset.blocked = false
                asset.reachedEndPosition = false
            }
            
            hero.assets2Unblock.removeAll()
        }
    }
    
    func unblockAssets(state: RwaState)
    {
        for asset in state.assets {
            asset.blocked = false
        }
    }
    
    func entityIsWithinArea(_ area: RwaArea, _ offsetType: Int) -> Bool
    {
        var distance:Double
        var radiusInKm:Double
        var areaOffsetInMeters:Double
        var areaOffsetInKm:Double
        
        if(offsetType == RWAAREAOFFSETTYPE_ENTER)
        {
            areaOffsetInKm = area.enterOffset/1000;
            areaOffsetInMeters = area.enterOffset;
        }
        else if(offsetType == RWAAREAOFFSETTYPE_EXIT)
        {
            areaOffsetInKm = area.exitOffset/1000;
            areaOffsetInMeters = area.exitOffset;
        }
        else
        {
            areaOffsetInKm = 0;
            areaOffsetInMeters = 0;
        }
        
        if(area.areaType == Int(RWAAREATYPE_CIRCLE) )
        {
            distance = calculateDistance(hero.coordinates, p2: area.coordinates)
            radiusInKm = Double(area.radius/1000)
            if(distance < radiusInKm + areaOffsetInKm)
            {
                //print("Within Circle Area")
                return true
            }
        }
        
        if( (area.areaType == Int(RWAAREATYPE_SQUARE)) || (area.areaType == Int(RWAAREATYPE_RECTANGLE))  )
        {
            if(coordinateWithinRectangle(hero.coordinates, area.coordinates, Double(area.width) + areaOffsetInMeters, Double(area.height) + areaOffsetInMeters) ) {
                //print("Within Rect Area")
                return true
            }
        }
        
        if( area.areaType == Int(RWAAREATYPE_POLYGON)  )
        {
            //print("Within Polygon Area?")
            if(area.corners != nil)
            {
                if(offsetType == RWAAREAOFFSETTYPE_ENTER || (area.exitOffset == 0) )
                {
                    if(coordinateWithinPolygon(hero.coordinates, area.corners! )) {
                        return true
                    }
                }
                else
                {
                    if(coordinateWithinPolygon(hero.coordinates, area.exitOffsetCorners! )) {
                        return true
                    }
                }
            }
        }
        
        return false
    }
    
    func setEntityScene()
    {
        for scene in (scenes)
        {
            if(scene.level == hero.currentScene?.level)
            {
                //print("Found equal level Scene: \(String(describing: scene.name))")
                if(scene != hero.currentScene)
                {
                   // print("Found different equal level Scene: \(String(describing: scene.name))")
                    if(entityIsWithinArea(scene, RWAAREAOFFSETTYPE_ENTER))
                    {
                        sendEnd2BackgroundAssets()
                        sendEnd2ActiveAssets()
                        hero.currentScene = scene
                        hero.currentState?.blockUntilRadiusHasBeenLeft = false;
                        hero.currentState = hero.currentScene?.states[0]
                        hero.timeInCurrentState = 0
                        hero.timeInCurrentScene = 0
                        startBackgroundState()
                        sceneChanged = true
                        stateChanged = true
                        currentScene = scene.name;
                        
                        if #available(iOS 10.0, *) {
                            os_log("%@", type: .debug, "Enter Scene with new location: \(String(describing: scene.name))")
                        } else {
                            print("Enter Scene with new location: \(String(describing: scene.name))")
                        }
                    
                        return;
                    }
                }
            }
        }
    }
    
    func setEntityState()
    {
        var enterConditionsFulfilled = true
        var exitState = false
        var state = RwaState()
        var scene = RwaScene();
        var hint = RwaState()
        var newScene = String()
        
        if((hero.currentScene) == nil) {
            return
        }
        
        hero.timeInCurrentState += schedulerRate/1000
        hero.timeInCurrentScene += schedulerRate/1000
        
        if (fmod(hero.timeInCurrentState, 1) >= 0.01) {
            return;
        }
            
       /* else {
            if #available(iOS 10.0, *) {
                os_log("%@", type: .debug, "Time in current state: \(Int(hero.timeInCurrentState))")
            } else {
                print("Time in current state: \(Int(hero.timeInCurrentState))")
            }
        }*/
        
        if(hero.timeInCurrentState < (hero.currentState?.minStayTime)!) {
            return; }
        
        if(hero.timeInCurrentScene < (hero.currentScene?.minStayTime)!) {
            return; }
        
        setEntityScene()
        scene = hero.currentScene!;
        
        for state in (hero.currentScene?.states)!
        {
            let requiredStates = state.requiredStates
            
            if(state.type == Int32(RWASTATETYPE_GPS) && hero.currentState != state && !state.blockUntilRadiusHasBeenLeft)
            {
                if(entityIsWithinArea(state, RWAAREAOFFSETTYPE_ENTER))
                {
                
                    if(!requiredStates.isEmpty)
                    {
                        for requiredState in requiredStates
                        {
                            if(!hero.visitedStates.contains(requiredState))
                            {
                                enterConditionsFulfilled = false
                                if(state.hintState != "") {
                                    hint = (hero.currentScene?.getState(state.hintState))!
                                    state.blockUntilRadiusHasBeenLeft = true
                                }
                                
                                break;
                            }
                        }
                    }
                    
                    if(state.blockUntilRadiusHasBeenLeft) {
                        enterConditionsFulfilled = false
                    }
                    
                    if(state.enterOnlyOnce)
                    {
                        if(hero.visitedStates.contains(state.stateName)) {
                            enterConditionsFulfilled = false
                        }
                    }
                    
                    if(enterConditionsFulfilled)
                    {
                        stateChanged = true
                        sendEnd2ActiveAssets()
                        state.blockUntilRadiusHasBeenLeft = true
                        hero.currentState = state
                        if(!hero.visitedStates.contains(state.stateName)) {
                            hero.visitedStates.append(state.stateName)
                        }
                        
                        unblockAssets(state: state)
                        hero.timeInCurrentState = 0
                        
                        if #available(iOS 10.0, *) {
                            os_log("%@", type: .debug, "Enter State: \(String(describing: hero.currentState?.stateName))")
                        } else {
                            print("Enter State: \(String(describing: hero.currentState?.stateName))")
                        }
                    }
                }
            }
            
            if(state.blockUntilRadiusHasBeenLeft)
            {
                if(!entityIsWithinArea(state, RWAAREAOFFSETTYPE_EXIT)) {
                    state.blockUntilRadiusHasBeenLeft = false
                }
            }
        }
        
        state = hero.currentState!
        let background = hero.currentScene?.backgroundState
   
        if(hero.timeInCurrentState > state.timeOut && state.timeOut > 0)
        {
            sendEnd2ActiveAssets()
            exitState = true
        }
        
        if(hero.timeInCurrentScene > (background?.timeOut)! && Int((background?.timeOut)!) > 0)
        {
            newScene = (background?.nextScene)!
            if(newScene != "")
            {
                sendEnd2ActiveAssets()
                exitState = true
            }
        }
        
        if(state.leaveAfterAssetsFinish && hero.timeInCurrentState > 0)
        {
            if(hero.activeAssets.isEmpty)
            {
                exitState = true
                
                if #available(iOS 10.0, *) {
                    os_log("%@", type: .debug, "Leave after Assets Finish")
                } else {
                    print("Leave after Assets Finish")
                }
            }
        }
        
        if(hero.currentState?.type == Int32(RWASTATETYPE_GPS))
        {
            if(!entityIsWithinArea(state, RWAAREAOFFSETTYPE_EXIT))
            {
                if( (!state.leaveOnlyAfterAssetsFinish && !scene.fallbackDisabled)
                    || state.stateWithinState)
                {
                    
                    sendEnd2ActiveAssets()
                    exitState = true
                }
                else
                {
                    if(hero.activeAssets.isEmpty)
                    {
                       // sendEnd2ActiveAssets()
                        exitState = true
                    }
                }
            }
        }
        
        if(hint.stateName != "") {
            exitState = true
        }
        
        if(exitState)
        {
            stateChanged = true
            if(hint.stateName != "")
            {
                let nextState:RwaState = hint
                if(hint != hero.currentState)
                {
                    unblockAssets(state: nextState)
                    hero.currentState = nextState
                    hero.timeInCurrentState = 0
                }
            }
            else if(state.nextScene != "")
            {
                sendEnd2BackgroundAssets()
                let nextScene:RwaScene = hero.getScene(sceneName: state.nextScene)
                
                hero.currentScene = nextScene
                hero.currentState = hero.currentScene?.states[0]
                hero.timeInCurrentState = 0
                hero.timeInCurrentScene = 0
                startBackgroundState()
                sceneChanged = true
                
                if #available(iOS 10.0, *) {
                    os_log("%@", type: .debug, "Enter Scene")
                } else {
                    print("Enter Scene")
                }
            }
                
            else if(newScene != "" )
            {
                sendEnd2BackgroundAssets()
                let nextScene:RwaScene = hero.getScene(sceneName: newScene)
                
                hero.currentScene = nextScene
                hero.currentState = hero.currentScene?.states[0]
                hero.timeInCurrentState = 0
                hero.timeInCurrentScene = 0
                startBackgroundState()
                sceneChanged = true
                
                if #available(iOS 10.0, *) {
                    os_log("%@", type: .debug, "Enter Scene after timeout")
                } else {
                    print("Enter Scene after timeout")
                }

            }
            
            else if(state.nextState != "")
            {
                let nextState:RwaState = (hero.currentScene?.getState(state.nextState))!
                unblockAssets(state: nextState)
                hero.currentState = nextState
                hero.timeInCurrentState = 0
            }
            else
            {
                if(!scene.fallbackDisabled)
                {
                    hero.currentState = hero.currentScene?.states[0]
                    hero.timeInCurrentState = 0
                    
                    if #available(iOS 10.0, *) {
                        os_log("%@", type: .debug, "Enter Fallbackstate")
                    } else {
                        print("Enter Fallbackstate")
                    }
                }
            }
        }
    }
    
    func calculateAssetChannelParameters(_ asset: RwaAsset, bearing: Double) -> CLLocation
    {
        var dx, dy: Double
        var mainLat, mainLon: CLLocationDegrees
        var tmpLat, tmpLon: CLLocationDegrees
        mainLat = asset.coordinates.latitude
        mainLon = asset.coordinates.longitude
        
        dy = cos(degrees2radians(bearing)) * asset.multiChannelSourceRadius
        dx = sin(degrees2radians(bearing)) * asset.multiChannelSourceRadius
        tmpLat = mainLat + (180/Double.pi) * (dy/6378137)
        tmpLon = mainLon + (180/Double.pi) * (dx/6378137)/cos(mainLat)
        let location:CLLocation = CLLocation(latitude: tmpLat, longitude: tmpLon)
        return location
    }
    
    func sendDistance(_ channel:Int,_ patcherTag:Int, _ distance: Float)
    {
        let pdChannel:Int = channel+1
        let distance2Pd:String = "\(patcherTag)-distance\(pdChannel)"
        PdBase.send(distance, toReceiver: distance2Pd)
    }
    
    func sendBearing(_ channel:Int,_ patcherTag:Int, _ bearing: Float)
    {
        let pdChannel:Int = channel+1
        let bearing2Pd:String = "\(patcherTag)-azimuth\(pdChannel)"
        PdBase.send(bearing, toReceiver: bearing2Pd)
    }
    
    func sendElevation(_ channel:Int,_ patcherTag:Int, _ elevation: Float)
    {
        let pdChannel:Int = channel+1
        let elevation2Pd:String = "\(patcherTag)-elevation\(pdChannel)"
        PdBase.send(elevation, toReceiver: elevation2Pd)
    }
    
    func getOffsetForChannel(_ channel:Int, playbackType:Int) -> Int
    {
        switch(playbackType)
        {
            case RWAPLAYBACKTYPE_BINAURALMONO:
                return 0;
            
            case RWAPLAYBACKTYPE_BINAURALMONO_FABIAN:
                return 0;
            
            case RWAPLAYBACKTYPE_BINAURALSTEREO:
            if(channel == 0)
                {return -60}
            if(channel == 1)
                {return 60}
            
            case RWAPLAYBACKTYPE_BINAURALSTEREO_FABIAN:
                if(channel == 0)
                    {return -60}
                if(channel == 1)
                    {return 60}
            
            case RWAPLAYBACKTYPE_BINAURAL5CHANNEL:
                if(channel == 0)
                    {return -60}
                if(channel == 1)
                    {return 0}
                if(channel == 2)
                    {return 60}
                if(channel == 3)
                    {return -120}
                if(channel == 4)
                    {return 120}
            
            case RWAPLAYBACKTYPE_BINAURAL5CHANNEL_FABIAN:
                if(channel == 0)
                    {return -60}
                if(channel == 1)
                    {return 0}
                if(channel == 2)
                    {return 60}
                if(channel == 3)
                    {return -120}
                if(channel == 4)
                    {return 120}
            
            default:
                return 0
        }
        return 0
    }
    
    func calculateChannelBearingAndDistance(_ channel:Int, _ asset:RwaAsset)
    {
        var offset = getOffsetForChannel(channel, playbackType: Int(asset.playbackType))
        offset += (360 - asset.rotateOffset) % 360;
        
        if(asset.individuellChannelPosition[channel] == false) {
            asset.channelCoordinates[channel] = calculateDestination(asset.currentPosition, asset.multiChannelSourceRadius, Double(Int(Float(offset)+asset.currentRotateAngleOffset)%360)) }

        if(asset.fixedAzimuth < 0) {
            asset.channelBearing[channel] = Float(calculateBearing(hero.coordinates, p2: asset.channelCoordinates[channel], headDirection: Double(azimuth)))
        }
        else {
            asset.channelBearing[channel] = Float(asset.fixedAzimuth + Double(offset))
        }
        
        if(asset.fixedDistance < 0)
        {
            if(asset.minDistance == -1) {
                asset.channelDistance[channel] = Float(calculateDistance(hero.coordinates, p2: asset.channelCoordinates[channel])) * 1000}
            else
            {
                asset.channelDistance[channel] = Float(calculateDistance(hero.coordinates, p2: asset.channelCoordinates[channel])) * 1000
                if(asset.channelDistance[channel] < Float(asset.minDistance)) {
                    asset.channelDistance[channel] = Float(asset.minDistance)
                 }
            }
        }
        else {
            asset.channelDistance[channel] = Float(asset.fixedDistance)
        }
    }
    
    func sendData2Asset(mapItem: RwaEntity.AssetMapItem)
    {
        var intPatcherTag: Int
        var end2Pd: String
        var lon2Pd: String
        var lat2Pd: String
        var step2Pd: String
        var asset: RwaAsset
        
        asset = mapItem.asset
        intPatcherTag = Int(mapItem.patcherTag)
        lon2Pd = "\(intPatcherTag)-lon"
        lat2Pd = "\(intPatcherTag)-lat"
        step2Pd = "\(intPatcherTag)-step"
        
        asset.elevation = -(Float)(elevation);
        
        if(Int(asset.type) == RWAASSETTYPE_PD)
        {
            PdBase.send(hero.coordinates.longitude, toReceiver: lon2Pd)
            PdBase.send(hero.coordinates.latitude, toReceiver: lat2Pd)
            
            calculateChannelBearingAndDistance(0, asset)
            sendDistance(0, intPatcherTag , asset.channelDistance[0])
            
            if(asset.headtrackerRelative2Source)
            {
                sendBearing(0, intPatcherTag , asset.channelBearing[0])
                sendElevation(0, intPatcherTag , asset.elevation)
            }
            else
            {
                sendBearing(0, intPatcherTag , Float(azimuth))
                sendElevation(0, intPatcherTag , Float(elevation))
            }
            
            if(stepCount != lastStep)
            {
                lastStep = stepCount
                PdBase.sendBang(toReceiver: step2Pd)
                print("STEP to Pd")
            }
        }
        else
        {
            if( (asset.playbackType == Int32(RWAPLAYBACKTYPE_BINAURALMONO)) ||
                (asset.playbackType == Int32(RWAPLAYBACKTYPE_BINAURALMONO_FABIAN)) ||
                (asset.playbackType == Int32(RWAPLAYBACKTYPE_MONO) ) ||
                (asset.playbackType == Int32(RWAPLAYBACKTYPE_STEREO)) )
            {
                calculateChannelBearingAndDistance(0, asset)
                sendDistance(0, intPatcherTag , asset.channelDistance[0])
                sendBearing(0, intPatcherTag , asset.channelBearing[0])
                sendElevation(0, intPatcherTag , asset.elevation)
            }
            
            if(asset.playbackType == Int32(RWAPLAYBACKTYPE_BINAURALSTEREO) ||
               asset.playbackType == Int32(RWAPLAYBACKTYPE_BINAURALSTEREO_FABIAN) )
            {
                for i in 0 ..< 2
                {
                    calculateChannelBearingAndDistance(i, asset)
                    sendDistance(i, intPatcherTag , asset.channelDistance[i])
                    sendBearing(i, intPatcherTag , asset.channelBearing[i])
                    sendElevation(i, intPatcherTag , asset.elevation)
                }
            }
            
            if(asset.playbackType == Int32(RWAPLAYBACKTYPE_BINAURAL5CHANNEL) ||
               asset.playbackType == Int32(RWAPLAYBACKTYPE_BINAURAL5CHANNEL_FABIAN))
            {
                for i in 0 ..< 5
                {
                    calculateChannelBearingAndDistance(i, asset)
                    sendDistance(i, intPatcherTag , asset.channelDistance[i])
                    sendBearing(i, intPatcherTag , asset.channelBearing[i])
                    sendElevation(i, intPatcherTag , asset.elevation)
                }
            }
            
            if(asset.playbackType == Int32(RWAPLAYBACKTYPE_BINAURAL7CHANNEL_FABIAN))
            {
                for i in 0 ..< 7
                {
                    calculateChannelBearingAndDistance(i, asset)
                    sendDistance(i, intPatcherTag , asset.channelDistance[i])
                    sendBearing(i, intPatcherTag , asset.channelBearing[i])
                    sendElevation(i, intPatcherTag , asset.elevation)
                }
            }
        }
        
        if(!asset.reachedEndPosition)
        {
            if(asset.distanceForMovement > 0)
            {
                asset.distanceForMovement -= asset.movingDistancePerTick;
                asset.currentPosition = calculateDestination(asset.coordinates, asset.distanceForMovement, asset.bearingForMovement)
            }
            else
            {
                asset.reachedEndPosition = true
                if(asset.loopUntilEndPosition) {
                    asset.blocked = true
                }
                
                hero.assets2Unblock.append(asset)
                end2Pd = "\(intPatcherTag)-end"
                PdBase.sendBang(toReceiver: end2Pd)
            }
        }
        
        if( (hero.timeInCurrentState * 1000 > (Double(asset.duration) + Double(asset.offset))) && !asset.loop && !asset.blocked && Int(asset.type) != RWAASSETTYPE_PD)
        {
            asset.blocked = true
            hero.assets2Unblock.append(asset)
            end2Pd = "\(intPatcherTag)-end"
            PdBase.sendBang(toReceiver: end2Pd)
        }
        
        if(asset.autoRotate) {
            asset.currentRotateAngleOffset += asset.rotateOffsetPerTick
        }
        
        if(asset.updatePlayheadPosition)
        {
            asset.playheadPositionWithoutOffset += Double(schedulerRate)
            if(asset.playheadPositionWithoutOffset >= Double(asset.offset)) {
                asset.playheadPosition += Double(schedulerRate)  * 44.1
            }
            
            if(asset.playheadPosition >= asset.fadeOutAfter * 44.1)
            {
                asset.playheadPosition = 0;
                if(asset.loop == false) {
                    asset.updatePlayheadPosition = false
                }
            }
        }
    }
    
    func sendData2ActiveAssets()
    {
        if(hero.currentState == nil) {
            return
        }
        
        if(hero.activeAssets.isEmpty) {
            return
        }
        
        for mapItem in hero.backgroundAssets
        {
            sendData2Asset(mapItem: mapItem.value);
        }
        
        for mapItem in hero.activeAssets
        {
            sendData2Asset(mapItem: mapItem.value);
        }
        step = 0;
    }
    
    func sendInitValues2Pd(_ asset:RwaAsset, _ patcherTag: Int)
    {
        var pdReceiver: String
        
        if(asset.moveFromStartPosition)
        {
            asset.currentPosition.latitude = asset.startPosition.latitude
            asset.currentPosition.longitude = asset.startPosition.longitude
            asset.reachedEndPosition = false
        }
        else
        {
            asset.currentPosition = asset.coordinates
            asset.reachedEndPosition = true
        }
        
        var firstCrossfadeAfter = asset.fadeOutAfter;
        asset.playheadPositionWithoutOffset = 0
        asset.updatePlayheadPosition = true;
        
        if(asset.alwaysPlayFromBeginning == true) {
            asset.playheadPosition = 0;
        }
        else
        {
            firstCrossfadeAfter -= (asset.playheadPosition/44.1)
            if(firstCrossfadeAfter < 0)
            {
                firstCrossfadeAfter = asset.fadeOutAfter
                asset.playheadPosition = 0
            }
        }
        
        asset.distanceForMovement = calculateDistance(asset.startPosition, p2: asset.coordinates) * 1000
        asset.movingDistancePerTick = Double(asset.movementSpeed) * Double(schedulerRate)/1000.0
        asset.rotateOffsetPerTick = Float(Double(asset.rotateFrequency) * 360.0 * Double(schedulerRate)/1000.0)
        asset.currentRotateAngleOffset = 0
        
        pdReceiver = "\(patcherTag)-playheadposition"
        PdBase.send((Double(asset.playheadPosition)), toReceiver: pdReceiver)
        
        pdReceiver = "\(patcherTag)-dampingfunction"
        PdBase.send((Double(asset.dampingFunction)), toReceiver: pdReceiver)
        
        pdReceiver = "\(patcherTag)-dampingfactor"
        PdBase.send(Double(asset.dampingFactor), toReceiver: pdReceiver)
        
        pdReceiver = "\(patcherTag)-dampingtrim"
        PdBase.send(Double(asset.dampingTrim), toReceiver: pdReceiver)
        
        pdReceiver = "\(patcherTag)-dampingmin"
        PdBase.send(Double(asset.dampingMin), toReceiver: pdReceiver)
        
        pdReceiver = "\(patcherTag)-dampingmax"
        PdBase.send(Double(asset.dampingMax), toReceiver: pdReceiver)
        
        pdReceiver = "\(patcherTag)-offset"
        PdBase.send(Double(asset.offset), toReceiver: pdReceiver)
        
        pdReceiver = "\(patcherTag)-loop"
        PdBase.send(boolean2Double(asset.loop), toReceiver: pdReceiver)
        
        pdReceiver = "\(patcherTag)-gain"
        PdBase.send(Double(asset.gain), toReceiver: pdReceiver)
        
        pdReceiver = "\(patcherTag)-fadeintime"
        PdBase.send(Double(asset.fadeInTime), toReceiver: pdReceiver)
        
        pdReceiver = "\(patcherTag)-fadeouttime"
        PdBase.send(Double(asset.fadeOutTime), toReceiver: pdReceiver)
        
        pdReceiver = "\(patcherTag)-crossfadetime"
        PdBase.send(Double(asset.crossfadeTime), toReceiver: pdReceiver)
        
        pdReceiver = "\(patcherTag)-firstcrossfade"
        PdBase.send(Double(firstCrossfadeAfter), toReceiver: pdReceiver)
        
        pdReceiver = "\(patcherTag)-crossfadeafter"
        PdBase.send(Double(asset.fadeOutAfter), toReceiver: pdReceiver)
        
        pdReceiver = "\(patcherTag)-play"
        let path = fullAssetPath + "/" + asset.name
        PdBase.sendSymbol(path , toReceiver: pdReceiver)
        
        if #available(iOS 10.0, *) {
            os_log("%@", type: .debug, "NEW ACTIVE ASSET: \(asset.name) send to receiver \(pdReceiver) crossfadeafter: \(asset.fadeOutAfter)")
        } else {
            print("NEW ACTIVE ASSET: \(asset.name) send to receiver \(pdReceiver) crossfadeafter: \(asset.fadeOutAfter)")
        }
    }
    
    func startBackgroundState()
    {
        var state: RwaState
        var gain2Pd: String
        var patcherTag: Int32
        
        state = (hero.currentScene?.backgroundState)!
        
        if(state.stateName == "") {
            return }
        if(state.assets.isEmpty) {
            return }
        
        for asset in state.assets
        {
            patcherTag = findFreePatcher(asset: asset)
            gain2Pd = "\(patcherTag)-gain"
            PdBase.send(asset.gain, toReceiver: gain2Pd)
            
            sendInitValues2Pd(asset, Int(patcherTag))
            let mapItem: RwaEntity.AssetMapItem = RwaEntity.AssetMapItem(asset, patcherTag)
            hero.backgroundAssets[asset.uniqueId] = mapItem
        }
    }
    
    func resetGame()
    {
        hero.timeInCurrentScene = 0;
        hero.timeInCurrentState = 0;
        
        if(!scenes.isEmpty)
        {
            for scene in scenes
            {
                
                for state in scene.states {
                    state.blockUntilRadiusHasBeenLeft = false
                    
                    for asset in state.assets {
                        asset.playheadPosition = 0
                        asset.playheadPositionWithoutOffset = 0
                        asset.updatePlayheadPosition = true;
                    }
                }
            }
        }
    }
    
    func startGame()
    {
        resetGame()
        
        if(!scenes.isEmpty)
        {
            hero.currentScene? = scenes[0]
            hero.currentState = hero.currentScene?.states[0]
            sceneChanged = true
            stateChanged = true
        }
        
        startBackgroundState()
    }
    
    func processAssets()
    {
        if(hero.currentState == nil) {
            return }
        if(hero.currentState?.assets.isEmpty)! {
            return }
        
        for asset in (hero.currentState?.assets)!
        {
            if(!hero.isActiveAsset(asset.uniqueId) && !asset.blocked && !asset.mute)
            {
                if #available(iOS 10.0, *) {
                    os_log("%@", type: .debug, "Start asset for state: \(String(describing: hero.currentState))")
                } else {
                    print("Start asset for state: \(String(describing: hero.currentState))")
                }
                
                let patcherTag = findFreePatcher(asset: asset)
                sendInitValues2Pd(asset, Int(patcherTag))
                hero.activeAssets[asset.uniqueId] = RwaEntity.AssetMapItem(asset, patcherTag)
                break
            }
        }
    }
    
    func updateGameState()
    {
        sendData2ActiveAssets()
        setEntityState()
        processAssets()
        
        hero.timeSinceLastGpsUpdate += Double(schedulerRate)
        if(!headTrackerConnected) {
            hero.disconnectedFromHeadtrackerSince += Double(schedulerRate)
        }
        
        if(hero.timeSinceLastGpsUpdate > 20000) {
            //print("Please Return, Gps seems broken")
        }
        
        if(hero.disconnectedFromHeadtrackerSince > 20000) {
            //print("Please Return, headtracker seems broken")
        }
    }
 
    func receiveBang(fromSource source: String!)
    {
        let parts = source.components(separatedBy: "-")
        var patcherTag: Int
        var gain2Pd: String
        
        if(parts.last == "playfinished")
        {
            patcherTag = Int(parts.first!)!
            for mapItem in hero.activeAssets
            {
                if(mapItem.value.patcherTag == Int32(patcherTag) )
                {
                    gain2Pd = "\(patcherTag)-gain"
                    PdBase.send(Double(0.0), toReceiver: gain2Pd)
                    hero.removeActiveAsset(Int32(patcherTag))
                    
                    if #available(iOS 10.0, *) {
                        os_log("%@", type: .debug, "Release patcher from asset \(mapItem.value.asset.name)")
                    } else {
                        print("Release patcher from asset \(patcherTag) \(mapItem.value.asset.name) ")
                    }
                    
                    releasePatcherFromItem(mapItem.value)
                }
            }
            
            for mapItem in hero.backgroundAssets
            {
                if(mapItem.value.patcherTag == Int32(patcherTag) )
                {
                    gain2Pd = "\(patcherTag)-gain"
                    PdBase.send(Double(0.0), toReceiver: gain2Pd)
                    hero.removeBackgroundAsset(Int32(patcherTag))
                    
                    if #available(iOS 10.0, *) {
                        os_log("%@", type: .debug, "Release patcher from asset \(mapItem.value.asset.name)")
                    } else {
                        print("Release patcher from asset \(patcherTag) \(mapItem.value.asset.name) ")
                    }
                    
                    releasePatcherFromItem(mapItem.value)
                    
                }
            }
        }
        
        if(parts.last == "back2ios") {
            print("bang")
        }
    }
    
    func receive(_ received: Float, fromSource source: String!) {
        
        if(source == "back2ios") {
            print("back2ios: \(received)")
        }
        
        if(source == "back2ios1") {
            print("back2ios1: \(received)")
        }
        
        if(source == "back2ios2") {
            print("back2ios2: \(received)")
        }
    }
    
    func receiveMessage(_ message: String!, withArguments arguments: [AnyObject]!, fromSource source: String!) {
        
        for i in 0 ..< arguments.count {
            print("message: \(arguments[i])")
        }
    }
    
    func receiveSymbol(_ symbol: String!, fromSource source: String!)
    {
        print("symbol: \(symbol))")
    }
}
