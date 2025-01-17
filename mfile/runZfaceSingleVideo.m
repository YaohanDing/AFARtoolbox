function runZfaceSingleVideo(zface_param,video_path,zface_video_path,...
                             fit_path,varargin)

% runZfaceSingleVideo saves zface video/fit files of a given video.
%   Input arguments:
%   - zface_param: a struct containing mesh/alt2 path.
%   - video_path: char array, the path of the video folder. 
%   - zface_video_path: char array, the full path of the output zface video. 
%   - fit_path: char array, the full path of the output zface fit file.
%   Optional input arguments:
%   - save_fit: boolean, if not to save fit file. Default true.
%   - save_video: boolean, if to save the tracked face video. Default true.

    % Parse optional arguments
    p = inputParser;
    default_verbose  = false;
    default_log_fn   = '';
    default_save_fit = true;
    default_save_video  = false;
    default_start_frame = -1;
    default_end_frame   = -1;
    addOptional(p,'verbose',default_verbose);
    addOptional(p,'log_fn',default_log_fn);
    addOptional(p,'save_fit',default_save_fit);
    addOptional(p,'save_video',default_save_video);
    addOptional(p,'start_frame',default_start_frame);
    addOptional(p,'end_frame',default_end_frame);
    parse(p,varargin{:}); 
    verbose  = p.Results.verbose;   
    log_fn   = p.Results.log_fn;
    save_fit = p.Results.save_fit;
    save_video  = p.Results.save_video;
    start_frame = p.Results.start_frame;
    end_frame   = p.Results.end_frame;

    if (~save_fit && ~save_video)
        % if not save fit or video, nothing to save, quit.
        return
    end

    log_fid = -1;
    if verbose
        if ~isempty(log_fn)
            log_fid = fopen(log_fn,'a+');
        end
        printWrite(sprintf('%s Processing zface on %s \n',getMyTime(),...
                   correctPathFormat(video_path)),log_fid);
    end

    [~,video_fname,video_ext] = fileparts(video_path);

 	mesh_path  = zface_param.mesh;
    alt2_path  = zface_param.alt2;

    zf = CZFace(mesh_path,alt2_path);
    vo = VideoReader(video_path);

    if save_video
        vw = VideoWriter(zface_video_path);
        vw.FrameRate = vo.FrameRate;
        open(vw);
    end
    
    fit    = [];
    ctrl2D = [];
    vo.CurrentTime  = 0;
    frame_index     = 0;
    fit_frame_index = 0;
    while hasFrame(vo)
        % Track each frame
        I = readFrame(vo);
        if frame_index == 0 && save_video % first frame
            h = InitDisplay(zf,I);
        end
        frame_index = frame_index + 1;
        
        if (start_frame < 0 && end_frame < 0)
        % If input arg doesn't specify the start/end frame, use frame_index.
        % Otherwise, check if current frame_index is within the given range.
            fit_frame_index = frame_index;
        else
            if (frame_index >= start_frame && frame_index <= end_frame)
            % if input args specify the start/end frame, incr fit_frame_index 
            % every iteration. Otherwise, skip this iteration.
                fit_frame_index = fit_frame_index + 1;
            else
                continue;
            end
        end


      [ ctrl2D, mesh2D, mesh3D, pars ] = zf.Fit( I, ctrl2D );
        if save_video
            UpdateDisplay( h, zf, I, ctrl2D, mesh2D, pars );
            F = getframe(h.fig);
            [X, Map] = frame2im(F);
            writeVideo(vw,X);
        end
        
        fit(fit_frame_index).frame     = frame_index;
        fit(fit_frame_index).isTracked = ~isempty(ctrl2D);
        if fit(fit_frame_index).isTracked
            fit(fit_frame_index).pts_2d   = ctrl2D;
            fit(fit_frame_index).pts_3d   = mesh3D;
            fit(fit_frame_index).headPose = pars(4:6);
            fit(fit_frame_index).pdmPars  = pars;
        else
            fit(fit_frame_index).pts_2d   = [];
            fit(fit_frame_index).pts_3d   = [];
            fit(fit_frame_index).headPose = [];
            fit(fit_frame_index).pdmPars  = [];
        end    
        if mod(fit_frame_index,500) == 0 && verbose 
            msg = sprintf('%s -- %d frames tracked from %s\n',getMyTime(),...
                          fit_frame_index,video_fname);
            printWrite(msg,log_fid);
        end

    end

    clear zf;

    if save_video
        close(h.fig);
        close(vw);
    end

    if save_fit
        save(fit_path,'fit');
    end

    if verbose
        printWrite(sprintf('%s %s tracking saved.\n',getMyTime(),...
                   correctPathFormat(video_path)),log_fid);
        if ~isempty(log_fn)
            fclose(log_fid);
        end
    end

end
