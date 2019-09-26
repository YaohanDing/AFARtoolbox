function runPipeline(video_dir,output_dir,zface_folder,FETA_folder,AU_folder,...
                     run_zface,run_FETA,run_AU_detector,varargin)
    % runPipeline processes the videos in the given folder thru zface, feta
    % and AU detector on the choice of callers.
    %   video_dir: the directory videos locate.
    %   output_dir: the top directory where the outputs will be.
    %   zface_folder: zface source code folder.
    %   FETA_folder: feta source code folder.
    %   AU_folder: au detector source code folder.
    %   run_zface: bool, if run videos thru zface.
    %   run_feta: bool, if run videos thru feta.
    %   run_AU_detector: bool, if run videos thru AU detector.

    p = inputParser;
    default_verbose    = false;
    default_save_log   = false;
    default_zface_save_fit   = true;
    default_zface_save_video = false;
    default_zface_parallel   = false;
    default_feta_resolution  = 200;
    default_feta_IOD         = 80;
    default_feta_patch_size  = 32;
    default_au_meansub       = false;
    addOptional(p,'verbose',default_verbose);
    addOptional(p,'save_log',default_save_log);
    addOptional(p,'zface_save_fit',default_zface_save_fit);
    addOptional(p,'zface_save_video',default_zface_save_video);
    addOptional(p,'zface_parallel',default_zface_parallel);
    addOptional(p,'feta_resolution',default_feta_resolution);
    addOptional(p,'feta_IOD',default_feta_IOD);
    addOptional(p,'feta_patch_size',default_feta_patch_size);
    addOptional(p,'au_meansub',default_au_meansub);
    parse(p,varargin{:});
    verbose    = p.Results.verbose;
    save_log   = p.Results.save_log;
    % zface parameters
    zface_save_fit   = p.Results.zface_save_fit;
    zface_save_video = p.Results.zface_save_video;
    zface_parallel   = p.Results.zface_parallel;
    % FETA parameters
    feta_resolution  = p.Results.feta_resolution;
    feta_IOD         = p.Results.feta_IOD;
    feta_patch_size  = p.Results.feta_patch_size;
    % AU parameters
    au_meansub       = p.Results.au_meansub;

    if ~isfolder(output_dir)
        error('Given output folder is not valid.\n');
    end
    
    if save_log
        log_fn = 'AFAR_process_log.txt';
        if isfile(log_fn)
            log_fid = fopen(log_fn,'a+');
        else
            log_fid = fopen(log_fn,'w');
        end
    else
        log_fid = -1;
    end

    % video dir with no backslash(bs)
    video_dir_nobs = correctPathFormat(video_dir);

    [zface_param,FETA_param,AU_param] = initOutDir(zface_folder,FETA_folder,...
                                        AU_folder,output_dir);
    addpath(genpath('.'));

    % ZFace module
    if run_zface
        if verbose
            printWrite(sprintf('\n%s Running Zface on %s\n',getMyTime(),...
                       video_dir_nobs),log_fid);
        end
        runZface(zface_param,video_dir,'save_fit',zface_save_fit,...
                 'save_video',zface_save_video,'multi_thread',...
                 zface_parallel,'verbose',verbose,'log_fid',log_fid);
    end
    
    % TODO: Add verbose option for FETA and AU detection.
    % FETA module
    load('ms3D_v1024_low_forehead.mat');
    FETA_param.lmSS = ':';
    FETA_param.res  = feta_resolution;
    FETA_param.IOD  = feta_IOD;
    FETA_param.ms3D = ms3D;
    FETA_param.normFeature = '2D_similarity';
    FETA_param.descFeature = 'HOG_OpenCV';
    FETA_param.patch_size  = feta_patch_size;
    % FETA_param.video_list  = getTrackingList(video_dir);
    if run_FETA
        if verbose
            printWrite(sprintf('\n%s Running FETA on %s\n',getMyTime(),...
                       video_dir_nobs),log_fid);
        end
        runFETA(zface_param,FETA_param,video_dir);
    end

    % AU detection module
    AU_param.nAU     = 12;
    AU_param.meanSub = au_meansub;
    if run_AU_detector
        if verbose
            printWrite(sprintf('\n%s Running AU detector %s\n',getMyTime(),...
                       video_dir_nobs),log_fid);
        end
        runAUdetector(FETA_param,AU_param,video_dir);
    end

end



