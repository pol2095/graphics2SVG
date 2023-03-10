package
{
	import flash.display.Shape;
	import flash.display.Sprite;
	
	import com.utils.graphics2SVG;
	
    public class Main extends Sprite
	{
        public function Main()
		{
			var shape:Shape = new Shape();
			shape.graphics.beginFill(0x0000FF);
			shape.graphics.drawRect( 0, 0, 100, 100);
			shape.graphics.endFill();
			this.addChild(shape);
			
			var svg:String = graphics2SVG( shape );
			
			trace(svg);
		}
    }
}
