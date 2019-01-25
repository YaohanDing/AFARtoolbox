
create_out = true; % run the pipeline need to set the value to be true to get
                        % all the output dir and subdir.
video_dir  = '/Users/wanqiaod/workspace/pipeline/test_video';
output_dir = '/Users/wanqiaod/workspace/pipeline/out';
run_zface  = true;
run_FETA   = true;
run_AU_detector = true;
zface_folder    = '/Users/wanqiaod/workspace/pipeline/zface';
FETA_folder     = '/Users/wanqiaod/workspace/pipeline/FETA';
AU_folder       = '/Users/wanqiaod/workspace/pipeline/AU_detector';


runPipeline(video_dir,output_dir,zface_folder,FETA_folder,AU_folder,...
            run_zface,run_FETA,run_AU_detector,create_out)





