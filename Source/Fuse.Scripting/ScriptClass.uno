using Uno;
using Uno.UX;
using Uno.Collections;

namespace Fuse.Scripting
{
	public enum ExecutionThread
	{
		Any,
		JavaScript,
		MainThread
	}

	public abstract class ScriptMember
	{
		public readonly string Name;

		protected ScriptMember(string name)
		{
			Name = name;
		}
	}

	public abstract class ScriptProperty: ScriptMember
	{
		public readonly string Modifier;
		protected ScriptProperty(string name, string modifier = null): base(name) 
		{
			Modifier = modifier ?? "";
		}
		public abstract Property GetProperty(PropertyObject owner);
	}

	public sealed class ScriptProperty<TOwner, TValue>: ScriptProperty
	{
		readonly Func<TOwner, Property<TValue>> _getter;
		public override Property GetProperty(PropertyObject owner) 
		{ 
			if (!(owner is TOwner)) throw new Exception("ScriptProperty: incorrect owner type");
			return _getter((TOwner)owner); 
		}
		public ScriptProperty(string name, Func<TOwner, Property<TValue>> getter, string modifier = null): base(name, modifier) 
		{
			_getter = getter;
		}
	}

	public abstract class ScriptMethod: ScriptMember
	{
		public readonly ExecutionThread Thread;

		protected ScriptMethod(string name, ExecutionThread thread): base(name)
		{
			Thread = thread;
		}

		public abstract object Call(Context c, object obj, object[] args);
	}

	public class ScriptMethodInline: ScriptMethod
	{
		public readonly string Code;

		public ScriptMethodInline(string name, ExecutionThread thread, string code): base(name, thread)
		{
			Code = code;
		}

		public override object Call(Context c, object obj, object[] args)
		{
			throw new Exception(); // Not applicable
		}
	}

	public class ScriptMethod<T>: ScriptMethod
	{
		readonly Func<Context, T, object[], object> _method;
		readonly Action<Context, T, object[]> _voidMethod;

		public ScriptMethod(string name, Func<Context, T, object[], object> method, ExecutionThread thread): base(name, thread)
		{
			_method = method;
		}

		public ScriptMethod(string name, Action<Context, T, object[]> method, ExecutionThread thread): base(name, thread)
		{
			_voidMethod = method;
		}

		public override object Call(Context c, object obj, object[] args)
		{
			if (Thread == ExecutionThread.MainThread)
			{
				if (_voidMethod == null)
				{
					Fuse.Diagnostics.InternalError( "Cannot call a non-void method asynchronously", this );
					return null;
				}
				
				UpdateManager.PostAction(new CallClosure(_voidMethod, c, obj, args).Run);
				return null;
			}
			
			if (_voidMethod != null)
			{
				_voidMethod(c, (T)obj, args);
				return null;
			}
			else
			{
				return _method(c, (T)obj, args);
			}
		}
		
		class CallClosure
		{
			readonly Action<Context, T, object[]> _method;
			readonly object _obj;
			readonly Context _context;
			readonly object[] _args;

			public CallClosure(Action<Context, T, object[]> method, Context c, object obj, object[] args)
			{
				_method = method;
				_context = c;
				_obj = obj;
				_args = args;
			}

			public void Run()
			{
				_method(_context, (T)_obj, _args);
			}
		}
		
	}

	public class ScriptClass
	{
		readonly Type _unoType;
		public Type Type { get { return _unoType; } }
		public ScriptClass SuperType
		{
			get
			{
				return Get(_unoType.BaseType);
			}
		}

		public static ScriptClass Get(Type t)
		{
			while (t != null)
			{
				ScriptClass sc;
				if (_unoTypeToScriptClass.TryGetValue(t, out sc))
					return sc;
				t = t.BaseType;
			}
			return null;
		}

		static Dictionary<Type, ScriptClass> _unoTypeToScriptClass = new Dictionary<Type, ScriptClass>();

		readonly ScriptMember[] _members;
		public ScriptMember[] Members { get { return _members; } }
		
		ScriptClass(Type unoType, ScriptMember[] members)
		{
			_unoType = unoType;
			_members = members;
		}

		public static void Register(Type unoType, params ScriptMember[] members)
		{
			_unoTypeToScriptClass.Add(unoType, new ScriptClass(unoType, members));
		}
	}
}