/*
AUTH GATE - This will continuosluy listen for auth state changes

----------------------------------------------------------------

unauthenticated -> Login Page
authenticated -> Home Page

*/

import 'package:flutter/material.dart';
import 'package:pocketed/pages/home_page.dart';
import 'package:pocketed/pages/login_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      //Listen to auth state changes
      stream: Supabase.instance.client.auth.onAuthStateChange,
      //Build approriate page based on auth state
       
      builder: (context,snapshot){
        //loading.....
        if(snapshot.connectionState == ConnectionState.waiting){
          return const Scaffold(
            body: Center(child: CircularProgressIndicator(),),
          );
        }

        //check if there is a valid session currently
        final session=snapshot.hasData?snapshot.data?.session:null;

        if(session!=null){
          return HomePage();
        }else{
          return LoginPage();
        }
      });
  }
}