function [figure1 axes1] = create_plot(figure_in, axis_in, cascade, Y1, legend_entry, x_label, y_lable, figure_title, xmin, xmax, ymin, ymax)

x_tick_names1{1} = 'input';
for n = 1:1:max(size(cascade))
   x_tick_names1{n + 1} = cascade{n}.name;
end

if ishandle(figure_in)
   figure1 = figure_in;
   axes1 = axis_in;
else
   figure1 = figure;
   axes1 = axes('Parent',figure1);
   hold(axes1,'on');
   box(axes1,'on');
   if ~isempty(x_label)
      xlabel(x_label);
   end
   if ~isempty(y_lable)
      ylabel(y_lable);
   end
   if ~isempty(figure_title)
      title(figure_title);
   end
   if ~isempty(xmin) && ~isempty(xmax)
      xlim(axes1,[xmin xmax]);
   end
   if ~isempty(ymin) && ~isempty(ymax)
      ylim(axes1,[ymin ymax]);
   end
   set(axes1,'FontName','Times New Roman','XGrid','on',...
       'XTick',1:1:(max(size(cascade)) + 1),'XTickLabel',...
       x_tick_names1,'XTickLabelRotation', 30,'YGrid','on');
   legend1 = legend(axes1,'show');
   set(legend1,'Location','northeast','FontSize',10);
end

plot(axes1, Y1,'DisplayName',legend_entry);

end

