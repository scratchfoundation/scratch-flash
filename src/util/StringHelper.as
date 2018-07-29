package util {
public class StringHelper {
    /**
     * Convert all JavaScript escape characters into normal characters
     *
     * @param input The input string to convert
     * @return Original string with escape characters replaced by real characters
     */
    public static function unescapeString( input:String ):String
    {
        var result:String = "";
        var backslashIndex:int = 0;
        var nextSubstringStartPosition:int = 0;
        var len:int = input.length;

        do
        {
            // Find the next backslash in the input
            backslashIndex = input.indexOf( '\\', nextSubstringStartPosition );

            if ( backslashIndex >= 0 )
            {
                result += input.substr( nextSubstringStartPosition, backslashIndex - nextSubstringStartPosition );

                // Move past the backslash and next character (all escape sequences are
                // two characters, except for \u, which will advance this further)
                nextSubstringStartPosition = backslashIndex + 2;

                // Check the next character so we know what to escape
                var escapedChar:String = input.charAt( backslashIndex + 1 );
                switch ( escapedChar )
                {
                    // Try to list the most common expected cases first to improve performance

                    case '"':
                        result += escapedChar;
                        break; // quotation mark
                    case '\\':
                        result += escapedChar;
                        break; // reverse solidus   
                    case 'n':
                        result += '\n';
                        break; // newline
                    case 'r':
                        result += '\r';
                        break; // carriage return
                    case 't':
                        result += '\t';
                        break; // horizontal tab    

                    // Convert a unicode escape sequence to it's character value
                    case 'u':

                        // Save the characters as a string we'll convert to an int
                        var hexValue:String = "";

                        var unicodeEndPosition:int = nextSubstringStartPosition + 4;

                        // Make sure there are enough characters in the string leftover
                        if ( unicodeEndPosition > len )
                        {
                            parseError( "Unexpected end of input.  Expecting 4 hex digits after \\u." );
                        }

                        // Try to find 4 hex characters
                        for ( var i:int = nextSubstringStartPosition; i < unicodeEndPosition; i++ )
                        {
                            // get the next character and determine
                            // if it's a valid hex digit or not
                            var possibleHexChar:String = input.charAt( i );
                            if ( !isHexDigit( possibleHexChar ) )
                            {
                                parseError( "Excepted a hex digit, but found: " + possibleHexChar );
                            }

                            // Valid hex digit, add it to the value
                            hexValue += possibleHexChar;
                        }

                        // Convert hexValue to an integer, and use that
                        // integer value to create a character to add
                        // to our string.
                        result += String.fromCharCode( parseInt( hexValue, 16 ) );

                        // Move past the 4 hex digits that we just read
                        nextSubstringStartPosition = unicodeEndPosition;
                        break;

                    case 'f':
                        result += '\f';
                        break; // form feed
                    case '/':
                        result += '/';
                        break; // solidus
                    case 'b':
                        result += '\b';
                        break; // bell
                    default:
                        result += '\\' + escapedChar; // Couldn't unescape the sequence, so just pass it through
                }
            }
            else
            {
                // No more backslashes to replace, append the rest of the string
                result += input.substr( nextSubstringStartPosition );
                break;
            }

        } while ( nextSubstringStartPosition < len );

        return result;
    }

    /**
     * Determines if a character is a digit [0-9].
     *
     * @return True if the character passed in is a digit
     */
    private static function isDigit( ch:String ):Boolean
    {
        return ( ch >= '0' && ch <= '9' );
    }

    /**
     * Determines if a character is a hex digit [0-9A-Fa-f].
     *
     * @return True if the character passed in is a hex digit
     */
    private static function isHexDigit( ch:String ):Boolean
    {
        return ( isDigit( ch ) || ( ch >= 'A' && ch <= 'F' ) || ( ch >= 'a' && ch <= 'f' ) );
    }

    /**
     * Raises a parsing error with a specified message, tacking
     * on the error location and the original string.
     *
     * @param message The message indicating why the error occurred
     */
    private static function parseError( message:String ):void
    {
        throw new Error( message );
    }

}
}