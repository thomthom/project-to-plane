#-----------------------------------------------------------------------------
# Compatible: SketchUp 7 (PC)
#             (other versions untested)
#-----------------------------------------------------------------------------
#
# CHANGELOG
# 1.0.0 - 04.02.2011
#		 * Initial release.
#
#-----------------------------------------------------------------------------
#
# Thomas Thomassen
# thomas[at]thomthom[dot]net
#
#-----------------------------------------------------------------------------

require 'sketchup.rb'
require 'TT_Lib2/core.rb'

TT::Lib.compatible?('2.5.0', 'TT Project to Plane')

#-----------------------------------------------------------------------------

module TT::Plugins::ProjectToPlane
  
  ### CONSTANTS ### --------------------------------------------------------
  
  VERSION = '1.0.0'.freeze
  PREF_KEY = 'TT_ProjectToPlane'.freeze
  
  
  ### MODULE VARIABLES ### -------------------------------------------------
  
  # Preference
  #@settings = TT::Settings.new(PREF_KEY)
  #@settings.set_default( :gb_group,   'No' )
  
  
  ### MENU & TOOLBARS ### --------------------------------------------------
  
  unless file_loaded?( __FILE__ )
    m = TT.menu('Tools')
    m.add_item('Project to Plane')  { self.project_to_plane_tool }
  end
  
  
  ### MAIN SCRIPT ### ------------------------------------------------------
  
  
  def self.project_to_plane_tool
    Sketchup.active_model.select_tool( ProjectToPlaneTool.new )
  end
  
  
  class ProjectToPlaneTool
    
    def initialize
      @points = []
      @ip = Sketchup::InputPoint.new
    end
    
    def resume( view )
      view.invalidate
    end
    
    def deactivate( view )
      view.invalidate
    end
    
    def onCancel( reason, view )
      # 0: the user canceled the current operation by hitting the escape key.
      # 1: the user re-selected the same tool from the toolbar or menu.
      # 2: the user did an undo while the tool was active.
      if [0,1].include?( reason )
        reset( view )
      end
    end
    
    def onMouseMove( flags, x, y, view )
      @ip.pick( view, x, y )
      view.tooltip = @ip.tooltip
      view.invalidate
    end
    
    def onLButtonUp( flags, x, y, view )
      pt = @ip.position
      @points << pt if pt
      view.invalidate
    end
    
    def onLButtonDoubleClick( flags, x, y, view )
      puts 'Commit'
      reset( view )
    end
    
    def draw( view )
      @ip.draw( view ) if @ip.valid?
      
      if @points.size > 1
        view.line_width = 1
        view.line_stipple = ''
        view.drawing_color = [128, 0, 0]
        view.draw( GL_LINE_STRIP, @points )
      end
      
      if @points.size > 3
        plane = Geom.fit_plane_to_points( @points )
        
        projected = @points.map { |pt|
          line = [pt, Z_AXIS]
          new_pt = Geom.intersect_line_plane( line, plane )
        }.compact
        
        if projected.size > 1
          view.drawing_color = Sketchup::Color.new(0, 128, 0, 64)
          view.draw( GL_POLYGON, projected )
          
          view.line_width = 1
          view.line_stipple = ''
          view.drawing_color = Sketchup::Color.new(0, 128, 0)
          view.draw( GL_LINE_STRIP, projected )
        end
      end
    end
    
    def reset( view )
      @points.clear
      view.invalidate
    end
    
  end # class ProjectToPlaneTool
  
  
  ### DEBUG ### ------------------------------------------------------------  
  
  def self.reload
    load __FILE__
  end
  
end # module

#-----------------------------------------------------------------------------
file_loaded( __FILE__ )
#-----------------------------------------------------------------------------