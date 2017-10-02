// O(log n)
public binarySort(Array[], Size, Finder)
{
	new st = 0, dr = Size - 1, m;
	while ( st <= dr )
	{
		m = (st + dr) / 2;
		if ( Array[m] == Finder )
		{
			return m;
		}
			
		if ( x > Array[m] )
			st = m + 1;
		else
			dr = m - 1;
	}
	return -1;
}