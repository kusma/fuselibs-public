using Uno;
using Uno.UX;

using Fuse.Scripting;

namespace Fuse.Selection
{

	public partial class Selection
	{
		static Selection()
		{
			ScriptClass.Register(typeof(Selection),
				new ScriptMethod<Selection>("clear", clear, ExecutionThread.MainThread),
				new ScriptMethod<Selection>("add", add, ExecutionThread.MainThread),
				new ScriptMethod<Selection>("remove", remove, ExecutionThread.MainThread),
				new ScriptMethod<Selection>("forceAdd", forceAdd, ExecutionThread.MainThread),
				new ScriptMethod<Selection>("forceRemove", forceRemove, ExecutionThread.MainThread),
				new ScriptMethod<Selection>("toggle", toggle, ExecutionThread.MainThread));
		}
		
		/**
			Clears all selected items. 
			
			This does not respect restrictions, such as `MinCount`, and results in 0 items being selected.
		*/
		static void clear(Context c, Selection s, object[] args)
		{
			if (args.Length != 0)
			{
				Fuse.Diagnostics.UserError( "clear requires 0 arguments", s );
				return;
			}
			
			s.Clear();
		}

		/**
			Adds a string value to the selection.
			
			This follows the high level selection rules (such as MaxCount and Replace).
			
			This cannot verify that there is actually a @Selectable with this value.
		*/
		static void add(Context c, Selection s, object[] args)
		{
			if (args.Length != 1)
			{
				Fuse.Diagnostics.UserError( "add requires 1 argument, the value of the item", s );
				return;
			}
			
			s.Add( Marshal.ToType<string>(args[0]) );
		}
		
		/**
			Removes a string value from the selection.
			
			This follows the high level selection rules (such as MinCount).
			
			If the value is not in the selection then nothing is removed.
		*/
		static void remove(Context c, Selection s, object[] args)
		{
			if (args.Length != 1)
			{
				Fuse.Diagnostics.UserError( "remove requires 1 argument, the value of the item", s );
				return;
			}

			s.Remove( Marshal.ToType<string>(args[0]) );
		}
		
		/**
			Adds a string value to the selection even if it would violate the high level selection rules. A duplicate value will however not be added.
		*/
		static void forceAdd(Context c, Selection s, object[] args)
		{
			if (args.Length != 1)
			{
				Fuse.Diagnostics.UserError( "forceAdd requires 1 argument, the value of the item", s );
				return;
			}
			
			s.ForceAdd( Marshal.ToType<string>(args[0]) );
		}
		
		/**
			Removes a string value from the selection even if it would violate the high level selection rules.
		*/
		static void forceRemove(Context c, Selection s, object[] args)
		{
			if (args.Length != 1)
			{
				Fuse.Diagnostics.UserError( "forceRemove requires 1 argument, the value of the item", s );
				return;
			}

			s.ForceRemove( Marshal.ToType<string>(args[0]) );
		}
		
		/**
			Toggles the selection of a string value in the selection. If already selected then removes it, otherwise adds it.
			
			This follows the high level selection rules (such as MaxCount/MinCount).
		*/
		static void toggle(Context c, Selection s, object[] args)
		{
			if (args.Length != 1)
			{
				Fuse.Diagnostics.UserError( "toggle requires 1 argument, the value of them item", s );
				return;
			}
			
			s.Toggle( Marshal.ToType<string>(args[0]) );
		}
		
	}
}