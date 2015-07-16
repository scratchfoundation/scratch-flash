/**
 * Created by shanemc on 7/15/15.
 */
package blocks {
import flash.display.Sprite;

public class BlockStack extends Sprite {
	public var firstBlock:Block;
	public function BlockStack(b:Block) {
		x = b.x;
		y = b.y;
		b.x = b.y = 0;
		addChild(b);

		firstBlock = b;
		var nextBlock:Block = b.nextBlock;
		while (nextBlock) {
			addChild(nextBlock);
			nextBlock = nextBlock.nextBlock;
		}
	}
}
}
