% ==========================================================================
% Copyright (C) 2014 WYSIWYD Consortium, European Commission FP7 Project ICT-612139
% Authors: Hyung Jin Chang
% email:   (hj.chang@imperial.ac.uk)
% Permission is granted to copy, distribute, and/or modify this program
% under the terms of the GNU General Public License, version 2 or any
% later version published by the Free Software Foundation.
% 
% A copy of the license can be found at
% wysiwyd/license/gpl.txt
% 
% This program is distributed in the hope that it will be useful, but
% WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General
% Public License for more details
% ==========================================================================

function out = saveKineStruct(y, KineStruct, cdata, videoName)

% Drawing the connections with video
% load init image

augmented_result_save_ON = true;

if augmented_result_save_ON
    % clean and make a saving directory
    [SUCCESS,MESSAGE,MESSAGEID] = rmdir('result','s');
    mkdir('result');
    mkdir('result/video');
    mkdir('result/video/graph');
    mkdir('result/video/points');
    
    mkdir('result/images');
    mkdir('result/images/graph');
    mkdir('result/images/points');
    
    result_save_folder_video_graph = 'result/video/graph/';
    result_save_folder_video_points = 'result/video/points/';
    result_save_folder_images_graph = 'result/images/graph/';
    result_save_folder_images_points = 'result/images/points/';
    
    writerobj_graph = VideoWriter([result_save_folder_video_graph,'result_video_graph.avi']);
    writerobj_points = VideoWriter([result_save_folder_video_points,'result_video_points.avi']);
    
    open(writerobj_graph);
    open(writerobj_points);
end

videoFileName = cdata.filename(1:end-4);
videoObj = VideoReader([cdata.pathname,cdata.filename]);

%%
% Draw structure with points
h_points=figure(1001);
color_idx = 'rgbcmyk';
marker_idx = '+o*xsd^v><ph';
    
for frm_idx = 1:cdata.nFrames

    curFrame = read(videoObj,frm_idx);
    
    clf
    imshow(curFrame,'Border','tight');
    hold on
    
    % feature points
    for i=1:KineStruct.num_seg
        plot(y(1,KineStruct.seg_idx{i},frm_idx), y(2,KineStruct.seg_idx{i},frm_idx),marker_idx(mod(i,12)+1), 'Color', color_idx(mod(i,7)+1), 'LineWidth', 3, 'MarkerSize', 7);
        hold on
        plot(y(1,KineStruct.seg_idx{i},frm_idx), y(2,KineStruct.seg_idx{i},frm_idx),marker_idx(mod(i,12)+1), 'Color', 'w', 'LineWidth', 1, 'MarkerSize', 7);
    end
    
    pause(0.003)
    
    % get image from figure
    if augmented_result_save_ON
        F_points = getframe(h_points);
        writeVideo(writerobj_points,F_points);
    
    % save images
        save_image_filename=[sprintf('%04d',frm_idx) '.png'];
        save_path = [result_save_folder_images_points,save_image_filename];
        imwrite(F_points.cdata,save_path);
    end
end

%%
if augmented_result_save_ON
    close(writerobj_graph);
    close(writerobj_points);
end

%%
switch videoName
    case 'webCam'
        
    case 'video'
        
    case 'images'
        
    case 'YARP'
        wrapper_YARP_ABM_save;
end
end