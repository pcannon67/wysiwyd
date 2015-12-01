function img_output = genMatchImage_VideoSave_multipleMatches(KineStruct_P, KineStruct_Q, KineStruct_R, X_P_Q, X_P_R, X_Q_R, method, pathname_P, pathname_Q, pathname_R)

fig_video_save_name = ['result/realSeq/',KineStruct_P.videoFileName(1:end-4),'-',KineStruct_Q.videoFileName(1:end-4),'-',KineStruct_R.videoFileName(1:end-4),'-',method];
writerObj = VideoWriter([fig_video_save_name,'.avi']);
open(writerObj);

%%
num_max_Frm = max([KineStruct_P.num_frames-1,KineStruct_Q.num_frames-1,KineStruct_R.num_frames-1]);
frm_idx_set_P = ones(1,num_max_Frm)*(KineStruct_P.num_frames-1);
frm_idx_set_Q = ones(1,num_max_Frm)*(KineStruct_Q.num_frames-1);
frm_idx_set_R = ones(1,num_max_Frm)*(KineStruct_R.num_frames-1);
frm_idx_set_P(1:KineStruct_P.num_frames-1) = [1:KineStruct_P.num_frames-1];
frm_idx_set_Q(1:KineStruct_Q.num_frames-1) = [1:KineStruct_Q.num_frames-1];
frm_idx_set_R(1:KineStruct_R.num_frames-1) = [1:KineStruct_R.num_frames-1];

%%
% nFrm = 30;
% num_max_Frm = nFrm;
% frm_idx_set_P = [floor(KineStruct_P.num_frames/nFrm):floor((KineStruct_P.num_frames-1)/nFrm):KineStruct_P.num_frames-1];
% frm_idx_set_Q = [floor(KineStruct_Q.num_frames/nFrm):floor((KineStruct_Q.num_frames-1)/nFrm):KineStruct_Q.num_frames-1];

%%
xyloObj_P = VideoReader([pathname_P,KineStruct_P.videoFileName]);
xyloObj_Q = VideoReader([pathname_Q,KineStruct_Q.videoFileName]);
xyloObj_R = VideoReader([pathname_R,KineStruct_R.videoFileName]);

width_P = KineStruct_P.width;
width_Q = KineStruct_Q.width;
width_R = KineStruct_R.width;
height_P = KineStruct_P.height;
height_Q = KineStruct_Q.height;
height_R = KineStruct_R.height;

height_normalised = 240;
width_normalised = 320;

%%
h = waitbar(0,'Generating Video...');
progress_step = 1;

for idx = 1:num_max_Frm
    waitbar(progress_step / num_max_Frm);
    progress_step = progress_step + 1;
    
    frm_idx_P = frm_idx_set_P(idx);
    frm_idx_Q = frm_idx_set_Q(idx);
    frm_idx_R = frm_idx_set_R(idx);
    
    %%
    % load video
    img_P = uint8(rgb2gray(read(xyloObj_P, frm_idx_P)));
    img_Q = uint8(rgb2gray(read(xyloObj_Q, frm_idx_Q)));
    img_R = uint8(rgb2gray(read(xyloObj_R, frm_idx_R)));
    %     img_acc_P = uint8(read(xyloObj_P, frm_idx_P));
    %     img_acc_Q = uint8(read(xyloObj_Q, frm_idx_Q));
    
    %%   
    % Combined image
    img_combined = zeros(2*height_normalised, 2*width_normalised);
    
    %---------------------------------------------------------------
    img_normalised_P = imresize(img_P, [height_normalised, NaN]);
    img_normalised_Q = imresize(img_Q, [height_normalised, NaN]);    
    img_normalised_R = imresize(img_R, [height_normalised, NaN]);    
    
    width_norm_P = size(img_normalised_P,2);
    width_norm_Q = size(img_normalised_Q,2);
    width_norm_R = size(img_normalised_R,2);    
    
    %     img_combined(:,1:width_norm_P,1) = img_acc_normalised_P(:,:,1);
    %     img_combined(:,1:width_norm_P,2) = img_acc_normalised_P(:,:,2);
    %     img_combined(:,1:width_norm_P,3) = img_acc_normalised_P(:,:,3);
    
    shifted_dist_w_P = round((width_norm_Q + width_norm_R-width_norm_P)/2);
    shifted_dist_w_Q = 0;
    shifted_dist_w_R = width_norm_Q;
    shifted_dist_h_P = 0;
    shifted_dist_h_Q = height_normalised;
    shifted_dist_h_R = height_normalised;
    
    img_combined(1:height_normalised,shifted_dist_w_P+1:shifted_dist_w_P+width_norm_P) = img_normalised_P;
    img_combined(shifted_dist_h_Q+1:end,1:width_norm_Q) = img_normalised_Q;    
    img_combined(shifted_dist_h_Q+1:end,width_norm_Q+1:width_norm_Q+width_norm_R) = img_normalised_R;    
    
    ratio_height_P = height_normalised/ KineStruct_P.height;
    ratio_width_P = width_norm_P / KineStruct_P.width;
    ratio_height_Q = height_normalised/ KineStruct_Q.height;
    ratio_width_Q = width_norm_Q / KineStruct_Q.width;
    ratio_height_R = height_normalised/ KineStruct_R.height;
    ratio_width_R = width_norm_R / KineStruct_R.width;    
    
    %---------------------------------------------------------------
    img_combined = uint8(img_combined);    
    %     img_combined = uint8(ones(size(img_combined,1), size(img_combined,2),3)*255);
    
    %%
    % draw image
    % figure(1011)
    h_result = figure(343);
    clf
    iptsetpref('ImshowBorder','tight')
    imshow(img_combined);
    
    % Drawing the connections with color segments
    color_idx = 'rgbcmy';
    % marker_idx = '+o*xsd^v><ph';
    marker_idx = '............';
    
    color_value = 0.99;
    %     color_value = 0.0;
    
    %%
    % for Graph P
    for i=1:KineStruct_P.num_seg
        hold on
        plot(KineStruct_P.y(1,KineStruct_P.seg_idx{i},frm_idx_P) * ratio_width_P + shifted_dist_w_P,...
            KineStruct_P.y(2,KineStruct_P.seg_idx{i},frm_idx_P) * ratio_height_P,...
            marker_idx(mod(i,12)+1),'Color', color_idx(mod(i,6)+1),'MarkerSize',10, 'LineWidth',3);
    end
    % for Graph Q
    for i=1:KineStruct_Q.num_seg
        hold on
        plot(KineStruct_Q.y(1,KineStruct_Q.seg_idx{i},frm_idx_Q) * ratio_width_Q,...
            KineStruct_Q.y(2,KineStruct_Q.seg_idx{i},frm_idx_Q) * ratio_height_Q + shifted_dist_h_Q,...
            marker_idx(mod(i,12)+1),'Color',color_idx(mod(i,6)+1),'MarkerSize',10, 'LineWidth',3);
    end
    % for Graph R
    for i=1:KineStruct_R.num_seg
        hold on
        plot(KineStruct_R.y(1,KineStruct_R.seg_idx{i},frm_idx_R) * ratio_width_R + shifted_dist_w_R,...
            KineStruct_R.y(2,KineStruct_R.seg_idx{i},frm_idx_R) * ratio_height_R + shifted_dist_h_R,...
            marker_idx(mod(i,12)+1),'Color',color_idx(mod(i,6)+1),'MarkerSize',10, 'LineWidth',3);
    end    
    
    %%
    % drawing kinematic structure for Graph P
    for m = 1:size(KineStruct_P.structure_i,1)
        hold on
        
        joint_pts_buf = KineStruct_P.joint_center{KineStruct_P.structure_i(m),KineStruct_P.structure_j(m)};
        
        % Connection
        plot([KineStruct_P.seg_center(1,KineStruct_P.structure_i(m),frm_idx_P) * ratio_width_P + shifted_dist_w_P,...
            joint_pts_buf(1,frm_idx_P) * ratio_width_P + shifted_dist_w_P],...
            [KineStruct_P.seg_center(2,KineStruct_P.structure_i(m),frm_idx_P) * ratio_height_P + shifted_dist_h_P,...
            joint_pts_buf(2,frm_idx_P) * ratio_height_P + shifted_dist_h_P],...
            '-','Color',[color_value,color_value,color_value],'LineWidth',4);
        plot([KineStruct_P.seg_center(1,KineStruct_P.structure_j(m),frm_idx_P) * ratio_width_P + shifted_dist_w_P,...
            joint_pts_buf(1,frm_idx_P) * ratio_width_P + shifted_dist_w_P],...
            [KineStruct_P.seg_center(2,KineStruct_P.structure_j(m),frm_idx_P) * ratio_height_P + shifted_dist_h_P,...
            joint_pts_buf(2,frm_idx_P) * ratio_height_P + shifted_dist_h_P],...
            '-','Color',[color_value,color_value,color_value],'LineWidth',4);
        
        % Node
        plot([KineStruct_P.seg_center(1,KineStruct_P.structure_i(m),frm_idx_P) * ratio_width_P + shifted_dist_w_P],...
            [KineStruct_P.seg_center(2,KineStruct_P.structure_i(m),frm_idx_P) * ratio_height_P + shifted_dist_h_P],'-ws',...
            'LineWidth',3,...
            'MarkerSize',15,...
            'MarkerEdgeColor',[color_value,color_value,color_value],...
            'MarkerFaceColor',[1.0,0.2,0.2]);
        plot([KineStruct_P.seg_center(1,KineStruct_P.structure_j(m),frm_idx_P) * ratio_width_P + shifted_dist_w_P],...
            [KineStruct_P.seg_center(2,KineStruct_P.structure_j(m),frm_idx_P) * ratio_height_P + shifted_dist_h_P],'-ws',...
            'LineWidth',3,...
            'MarkerSize',15,...
            'MarkerEdgeColor',[color_value,color_value,color_value],...
            'MarkerFaceColor',[1.0,0.2,0.2]);
        
        % Joint
        plot(joint_pts_buf(1,frm_idx_P) * ratio_width_P + shifted_dist_w_P,...
            joint_pts_buf(2,frm_idx_P) * ratio_height_P + shifted_dist_h_P,'wo',...
            'LineWidth',1,...
            'MarkerSize',9,...
            'MarkerEdgeColor',[color_value,color_value,color_value],...
            'MarkerFaceColor',[1.0,0.647,0.0]);
        plot(joint_pts_buf(1,frm_idx_P) * ratio_width_P + shifted_dist_w_P,...
            joint_pts_buf(2,frm_idx_P) * ratio_height_P + shifted_dist_h_P,'wx',...
            'LineWidth',1,...
            'MarkerSize',9,...
            'MarkerEdgeColor',[color_value,color_value,color_value],...
            'MarkerFaceColor',[1.0,0.647,0.0]);
    end
    % drawing kinematic structure for Graph Q
    for m = 1:size(KineStruct_Q.structure_i,1)
        hold on
        
        joint_pts_buf = KineStruct_Q.joint_center{KineStruct_Q.structure_i(m),KineStruct_Q.structure_j(m)};
        
        % Connection
        plot([KineStruct_Q.seg_center(1,KineStruct_Q.structure_i(m),frm_idx_Q) * ratio_width_Q + shifted_dist_w_Q,...
            joint_pts_buf(1,frm_idx_Q) * ratio_width_Q + shifted_dist_w_Q],...
            [KineStruct_Q.seg_center(2,KineStruct_Q.structure_i(m),frm_idx_Q) * ratio_height_Q + shifted_dist_h_Q,...
            joint_pts_buf(2,frm_idx_Q) * ratio_height_Q + shifted_dist_h_Q],...
            '-','Color',[color_value,color_value,color_value],'LineWidth',4);
        plot([KineStruct_Q.seg_center(1,KineStruct_Q.structure_j(m),frm_idx_Q) * ratio_width_Q + shifted_dist_w_Q,...
            joint_pts_buf(1,frm_idx_Q) * ratio_width_Q + shifted_dist_w_Q],...
            [KineStruct_Q.seg_center(2,KineStruct_Q.structure_j(m),frm_idx_Q) * ratio_height_Q + shifted_dist_h_Q,...
            joint_pts_buf(2,frm_idx_Q) * ratio_height_Q + shifted_dist_h_Q],...
            '-','Color',[color_value,color_value,color_value],'LineWidth',4);
        
        % Node
        plot([KineStruct_Q.seg_center(1,KineStruct_Q.structure_i(m),frm_idx_Q) * ratio_width_Q + shifted_dist_w_Q],...
            [KineStruct_Q.seg_center(2,KineStruct_Q.structure_i(m),frm_idx_Q) * ratio_height_Q + shifted_dist_h_Q],'-ws',...
            'LineWidth',3,...
            'MarkerSize',15,...
            'MarkerEdgeColor',[color_value,color_value,color_value],...
            'MarkerFaceColor',[1.0,0.2,0.2]);
        plot([KineStruct_Q.seg_center(1,KineStruct_Q.structure_j(m),frm_idx_Q) * ratio_width_Q + shifted_dist_w_Q],...
            [KineStruct_Q.seg_center(2,KineStruct_Q.structure_j(m),frm_idx_Q) * ratio_height_Q + shifted_dist_h_Q],'-ws',...
            'LineWidth',3,...
            'MarkerSize',15,...
            'MarkerEdgeColor',[color_value,color_value,color_value],...
            'MarkerFaceColor',[1.0,0.2,0.2]);
        
        % Joint
        plot(joint_pts_buf(1,frm_idx_Q) * ratio_width_Q + shifted_dist_w_Q,...
            joint_pts_buf(2,frm_idx_Q) * ratio_height_Q + shifted_dist_h_Q,'wo',...
            'LineWidth',1,...
            'MarkerSize',9,...
            'MarkerEdgeColor',[color_value,color_value,color_value],...
            'MarkerFaceColor',[1.0,0.647,0.0]);
        plot(joint_pts_buf(1,frm_idx_Q) * ratio_width_Q + shifted_dist_w_Q,...
            joint_pts_buf(2,frm_idx_Q) * ratio_height_Q + shifted_dist_h_Q,'wx',...
            'LineWidth',1,...
            'MarkerSize',9,...
            'MarkerEdgeColor',[color_value,color_value,color_value],...
            'MarkerFaceColor',[1.0,0.647,0.0]);        
    end
    
    % drawing kinematic structure for Graph R
    for m = 1:size(KineStruct_R.structure_i,1)
        hold on
        
        joint_pts_buf = KineStruct_R.joint_center{KineStruct_R.structure_i(m),KineStruct_R.structure_j(m)};
        
        % Connection
        plot([KineStruct_R.seg_center(1,KineStruct_R.structure_i(m),frm_idx_R) * ratio_width_R + shifted_dist_w_R,...
            joint_pts_buf(1,frm_idx_R) * ratio_width_R + shifted_dist_w_R],...
            [KineStruct_R.seg_center(2,KineStruct_R.structure_i(m),frm_idx_R) * ratio_height_R + shifted_dist_h_R,...
            joint_pts_buf(2,frm_idx_R) * ratio_height_R + shifted_dist_h_R],...
            '-','Color',[color_value,color_value,color_value],'LineWidth',4);
        plot([KineStruct_R.seg_center(1,KineStruct_R.structure_j(m),frm_idx_R) * ratio_width_R + shifted_dist_w_R,...
            joint_pts_buf(1,frm_idx_R) * ratio_width_R + shifted_dist_w_R],...
            [KineStruct_R.seg_center(2,KineStruct_R.structure_j(m),frm_idx_R) * ratio_height_R + shifted_dist_h_R,...
            joint_pts_buf(2,frm_idx_R) * ratio_height_R + shifted_dist_h_R],...
            '-','Color',[color_value,color_value,color_value],'LineWidth',4);
        
        % Node
        plot([KineStruct_R.seg_center(1,KineStruct_R.structure_i(m),frm_idx_R) * ratio_width_R + shifted_dist_w_R],...
            [KineStruct_R.seg_center(2,KineStruct_R.structure_i(m),frm_idx_R) * ratio_height_R + shifted_dist_h_R],'-ws',...
            'LineWidth',3,...
            'MarkerSize',15,...
            'MarkerEdgeColor',[color_value,color_value,color_value],...
            'MarkerFaceColor',[1.0,0.2,0.2]);
        plot([KineStruct_R.seg_center(1,KineStruct_R.structure_j(m),frm_idx_R) * ratio_width_R + shifted_dist_w_R],...
            [KineStruct_R.seg_center(2,KineStruct_R.structure_j(m),frm_idx_R) * ratio_height_R + shifted_dist_h_R],'-ws',...
            'LineWidth',3,...
            'MarkerSize',15,...
            'MarkerEdgeColor',[color_value,color_value,color_value],...
            'MarkerFaceColor',[1.0,0.2,0.2]);
        
        % Joint
        plot(joint_pts_buf(1,frm_idx_R) * ratio_width_R + shifted_dist_w_R,...
            joint_pts_buf(2,frm_idx_R) * ratio_height_R + shifted_dist_h_R,'wo',...
            'LineWidth',1,...
            'MarkerSize',9,...
            'MarkerEdgeColor',[color_value,color_value,color_value],...
            'MarkerFaceColor',[1.0,0.647,0.0]);
        plot(joint_pts_buf(1,frm_idx_R) * ratio_width_R + shifted_dist_w_R,...
            joint_pts_buf(2,frm_idx_R) * ratio_height_R + shifted_dist_h_R,'wx',...
            'LineWidth',1,...
            'MarkerSize',9,...
            'MarkerEdgeColor',[color_value,color_value,color_value],...
            'MarkerFaceColor',[1.0,0.647,0.0]);        
    end    
    
    %% Draw matches
    color_value = 0;
%     % P - Q
%     for p = 1:size(X_P_Q,1)
%         for q = 1:size(X_P_Q,2)
%             if X_P_Q(p,q) > 0
%                 hold on
%                 plot([KineStruct_P.seg_center(1,p,frm_idx_P) * ratio_width_P + shifted_dist_w_P,...
%                     KineStruct_Q.seg_center(1,q,frm_idx_Q) * ratio_width_Q + shifted_dist_w_Q],...
%                     [KineStruct_P.seg_center(2,p,frm_idx_P) * ratio_height_P + shifted_dist_h_P,...
%                     KineStruct_Q.seg_center(2,q,frm_idx_Q) * ratio_height_Q + shifted_dist_h_Q],...
%                     '-','Color',[color_value,color_value,color_value],...
%                     'LineWidth',3,...
%                     'MarkerSize',10,...
%                     'MarkerEdgeColor',[color_value,color_value,color_value],...
%                     'MarkerFaceColor',[1.0,0.2,0.2]);
%                 plot([KineStruct_P.seg_center(1,p,frm_idx_P) * ratio_width_P + shifted_dist_w_P,...
%                     KineStruct_Q.seg_center(1,q,frm_idx_Q) * ratio_width_Q + shifted_dist_w_Q],...
%                     [KineStruct_P.seg_center(2,p,frm_idx_P) * ratio_height_P + shifted_dist_h_P,...
%                     KineStruct_Q.seg_center(2,q,frm_idx_Q) * ratio_height_Q + shifted_dist_h_Q],'-y.',...
%                     'LineWidth',2,...
%                     'MarkerSize',10,...
%                     'MarkerEdgeColor','y',...
%                     'MarkerFaceColor',[1.0,0.2,0.2]);
%             end
%         end
%     end
%     
%     % P - R
%     for p = 1:size(X_P_R,1)
%         for r = 1:size(X_P_R,2)
%             if X_P_R(p,r) > 0
%                 hold on
%                 plot([KineStruct_P.seg_center(1,p,frm_idx_P) * ratio_width_P + shifted_dist_w_P,...
%                     KineStruct_R.seg_center(1,r,frm_idx_R) * ratio_width_R + shifted_dist_w_R],...
%                     [KineStruct_P.seg_center(2,p,frm_idx_P) * ratio_height_P + shifted_dist_h_P,...
%                     KineStruct_R.seg_center(2,r,frm_idx_R) * ratio_height_R + shifted_dist_h_R],...
%                     '-','Color',[color_value,color_value,color_value],...
%                     'LineWidth',3,...
%                     'MarkerSize',10,...
%                     'MarkerEdgeColor',[color_value,color_value,color_value],...
%                     'MarkerFaceColor',[1.0,0.2,0.2]);
%                 plot([KineStruct_P.seg_center(1,p,frm_idx_P) * ratio_width_P + shifted_dist_w_P,...
%                     KineStruct_R.seg_center(1,r,frm_idx_R) * ratio_width_R + shifted_dist_w_R],...
%                     [KineStruct_P.seg_center(2,p,frm_idx_P) * ratio_height_P + shifted_dist_h_P,...
%                     KineStruct_R.seg_center(2,r,frm_idx_R) * ratio_height_R + shifted_dist_h_R],'-g.',...
%                     'LineWidth',2,...
%                     'MarkerSize',10,...
%                     'MarkerEdgeColor','y',...
%                     'MarkerFaceColor',[1.0,0.2,0.2]);
%             end
%         end
%     end    
%     
%     % Q - R
%     for q = 1:size(X_Q_R,1)
%         for r = 1:size(X_Q_R,2)
%             if X_Q_R(q,r) > 0
%                 hold on
%                 plot([KineStruct_Q.seg_center(1,q,frm_idx_Q) * ratio_width_Q + shifted_dist_w_Q,...
%                     KineStruct_R.seg_center(1,r,frm_idx_R) * ratio_width_R + shifted_dist_w_R],...
%                     [KineStruct_Q.seg_center(2,q,frm_idx_Q) * ratio_height_Q + shifted_dist_h_Q,...
%                     KineStruct_R.seg_center(2,r,frm_idx_R) * ratio_height_R + shifted_dist_h_R],...
%                     '-','Color',[color_value,color_value,color_value],...
%                     'LineWidth',3,...
%                     'MarkerSize',10,...
%                     'MarkerEdgeColor',[color_value,color_value,color_value],...
%                     'MarkerFaceColor',[1.0,0.2,0.2]);
%                 plot([KineStruct_Q.seg_center(1,q,frm_idx_Q) * ratio_width_Q + shifted_dist_w_Q,...
%                     KineStruct_R.seg_center(1,r,frm_idx_R) * ratio_width_R + shifted_dist_w_R],...
%                     [KineStruct_Q.seg_center(2,q,frm_idx_Q) * ratio_height_Q + shifted_dist_h_Q,...
%                     KineStruct_R.seg_center(2,r,frm_idx_R) * ratio_height_R + shifted_dist_h_R],'-m.',...
%                     'LineWidth',2,...
%                     'MarkerSize',10,...
%                     'MarkerEdgeColor','y',...
%                     'MarkerFaceColor',[1.0,0.2,0.2]);
%             end
%         end
%     end        

    % P - Q - R
%     c = @colors;

%%% Custom RGB colour vectors

%     colour_teal = [18 150 155] ./ 255;
%     colour_lightgreen = [94 250 81] ./ 255;
%     colour_green = [12 195 82] ./ 255;
%     colour_lightblue = [8 180 238] ./ 255;
%     colour_darkblue = [1 17 181] ./ 255;
%     colour_yellow = [251 250 48] ./ 255;
%     colour_peach = [251 111 66] ./ 255;
    
%     match_color_idx = 'cmygrbcmygrb';
    match_color_idx = zeros(7,3);
    match_color_idx(1,:) = [18 150 155] ./ 255;
    match_color_idx(2,:) = [251 250 48] ./ 255;
    match_color_idx(3,:) = [12 195 82] ./ 255;
    match_color_idx(4,:) = [251 111 66] ./ 255;
    match_color_idx(5,:) = [1 17 181] ./ 255;
    match_color_idx(6,:) = [94 250 81] ./ 255;
    match_color_idx(7,:) = [8 180 238] ./ 255;
    match_color_idx = [match_color_idx;match_color_idx];
    
    
    for p = 1:size(X_P_Q,1)
        q = find(X_P_Q(p,:)==1);
        if X_P_Q(p,q) > 0
            hold on
            plot([KineStruct_P.seg_center(1,p,frm_idx_P) * ratio_width_P + shifted_dist_w_P,...
                KineStruct_Q.seg_center(1,q,frm_idx_Q) * ratio_width_Q + shifted_dist_w_Q],...
                [KineStruct_P.seg_center(2,p,frm_idx_P) * ratio_height_P + shifted_dist_h_P,...
                KineStruct_Q.seg_center(2,q,frm_idx_Q) * ratio_height_Q + shifted_dist_h_Q],...
                '-','Color',[color_value,color_value,color_value],...
                'LineWidth',3,...
                'MarkerSize',10,...
                'MarkerEdgeColor',[color_value,color_value,color_value],...
                'MarkerFaceColor',[1.0,0.2,0.2]);
            plot([KineStruct_P.seg_center(1,p,frm_idx_P) * ratio_width_P + shifted_dist_w_P,...
                KineStruct_Q.seg_center(1,q,frm_idx_Q) * ratio_width_Q + shifted_dist_w_Q],...
                [KineStruct_P.seg_center(2,p,frm_idx_P) * ratio_height_P + shifted_dist_h_P,...
                KineStruct_Q.seg_center(2,q,frm_idx_Q) * ratio_height_Q + shifted_dist_h_Q],'-','Color',match_color_idx(p,:),...
                'LineWidth',2,...
                'MarkerSize',10,...
                'MarkerEdgeColor',match_color_idx(p,:),...
                'MarkerFaceColor',[1.0,0.2,0.2]);
        end
        r = find(X_P_R(p,:)==1);
        if X_P_R(p,r) > 0
            hold on
            plot([KineStruct_P.seg_center(1,p,frm_idx_P) * ratio_width_P + shifted_dist_w_P,...
                KineStruct_R.seg_center(1,r,frm_idx_R) * ratio_width_R + shifted_dist_w_R],...
                [KineStruct_P.seg_center(2,p,frm_idx_P) * ratio_height_P + shifted_dist_h_P,...
                KineStruct_R.seg_center(2,r,frm_idx_R) * ratio_height_R + shifted_dist_h_R],...
                '-','Color',[color_value,color_value,color_value],...
                'LineWidth',3,...
                'MarkerSize',10,...
                'MarkerEdgeColor',[color_value,color_value,color_value],...
                'MarkerFaceColor',[1.0,0.2,0.2]);
            plot([KineStruct_P.seg_center(1,p,frm_idx_P) * ratio_width_P + shifted_dist_w_P,...
                KineStruct_R.seg_center(1,r,frm_idx_R) * ratio_width_R + shifted_dist_w_R],...
                [KineStruct_P.seg_center(2,p,frm_idx_P) * ratio_height_P + shifted_dist_h_P,...
                KineStruct_R.seg_center(2,r,frm_idx_R) * ratio_height_R + shifted_dist_h_R],'-','Color',match_color_idx(p,:),...
                'LineWidth',2,...
                'MarkerSize',10,...
                'MarkerEdgeColor',match_color_idx(p,:),...
                'MarkerFaceColor',[1.0,0.2,0.2]);
        end
        r = find(X_Q_R(q,:)==1);
        if X_Q_R(q,r) > 0
            hold on
            plot([KineStruct_Q.seg_center(1,q,frm_idx_Q) * ratio_width_Q + shifted_dist_w_Q,...
                KineStruct_R.seg_center(1,r,frm_idx_R) * ratio_width_R + shifted_dist_w_R],...
                [KineStruct_Q.seg_center(2,q,frm_idx_Q) * ratio_height_Q + shifted_dist_h_Q,...
                KineStruct_R.seg_center(2,r,frm_idx_R) * ratio_height_R + shifted_dist_h_R],...
                '-','Color',[color_value,color_value,color_value],...
                'LineWidth',3,...
                'MarkerSize',10,...
                'MarkerEdgeColor',[color_value,color_value,color_value],...
                'MarkerFaceColor',[1.0,0.2,0.2]);
            plot([KineStruct_Q.seg_center(1,q,frm_idx_Q) * ratio_width_Q + shifted_dist_w_Q,...
                KineStruct_R.seg_center(1,r,frm_idx_R) * ratio_width_R + shifted_dist_w_R],...
                [KineStruct_Q.seg_center(2,q,frm_idx_Q) * ratio_height_Q + shifted_dist_h_Q,...
                KineStruct_R.seg_center(2,r,frm_idx_R) * ratio_height_R + shifted_dist_h_R],'-','Color',match_color_idx(p,:),...
                'LineWidth',2,...
                'MarkerSize',10,...
                'MarkerEdgeColor',match_color_idx(p,:),...
                'MarkerFaceColor',[1.0,0.2,0.2]);
        end
    end
    
    %% Save result
    iptsetpref('ImshowBorder','tight')
    %     fig_save_name = ['result/realSeq/',KineStruct_P.videoFileName(1:end-4),'-',KineStruct_Q.videoFileName(1:end-4),'/',KineStruct_P.videoFileName(1:end-4),'-',KineStruct_Q.videoFileName(1:end-4),'-',num2str(idx),'-',method,'-skeleton'];
    %     fig_save_name = ['result/realSeq/',KineStruct_P.videoFileName(1:end-4),'-',KineStruct_Q.videoFileName(1:end-4),'/',KineStruct_P.videoFileName(1:end-4),'-',KineStruct_Q.videoFileName(1:end-4),'-',num2str(idx),'-',method];
    %     export_fig(fig_save_name,'-pdf');
    %%
    img_output = getimage;
    
    %%
    frame = getframe(h_result);
    writeVideo(writerObj,frame);
    
%     pause(0.5)
end
close(h)
close(writerObj);
end