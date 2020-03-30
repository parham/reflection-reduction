
% w = 10;
% h = 8;
% 
% [X,Y] = meshgrid(-70:70, -50:50);
% X = X ./ 70;
% Y = Y ./ 50;
% X(abs(X) < 0.8) = 0;
% Y(abs(Y) < 0.8) = 0;
% X = imgaussfilt(double(X),11);
% Y = imgaussfilt(double(Y),11);
% 
% nrm = sqrt(X.^2 + Y.^2);
% nrm = nrm / max(nrm,[], 'all');
% R = (sin(nrm)+1) ./ sqrt(nrm) ;
% G = (sin(nrm+2*pi/3)+1) ./ sqrt((nrm+2*pi/3)) ;
% B = 0.1 *(sin(nrm+2*pi/3)+1) ./ sqrt((nrm+2*pi/3)) ;
% 
% recNrm = abs(X + Y) + abs(X - Y);
% recNrm = recNrm / max(recNrm,[], 'all');
% recNrm = 1 - recNrm;
% recNrm2 = abs(X) + abs(Y);
% recNrm2 = recNrm2 / max(recNrm2, [], 'all');
% recNrm2 = 1 - recNrm2;
% 
% %recNrm2 = ((0.5 * w) .* sign(cos(X))) + ((0.5 * h) .* sign(sin(Y)));
% 
% montage({mat2gray(nrm), mat2gray(1- nrm), mat2gray(G), mat2gray(recNrm), mat2gray(recNrm2)});

refBlender = ReflectionBasedBlender();
[result, resMask] = refBlender.process(matches, reflectMap);
figure; imshow(result);
figure; imshow(resMask);